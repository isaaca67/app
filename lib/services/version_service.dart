import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VersionService {
  static const _keyLastCheck = 'last_version_check';
  static const _keyUpdateAvailable = 'update_available';
  static const _keyMinVersion = 'min_version';

  final String appVersion;
  final int appBuildNumber;

  VersionService({required this.appVersion, required this.appBuildNumber});

  Future<Map<String, dynamic>?> checkUpdate(String firestoreDocPath) async {
    if (kIsWeb) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_keyLastCheck) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastCheck < 60 * 60 * 1000) {
        final updateAvailable = prefs.getBool(_keyUpdateAvailable) ?? false;
        final minVersion = prefs.getString(_keyMinVersion) ?? '';
        if (updateAvailable && minVersion.isNotEmpty) {
          return {
            'updateAvailable': true,
            'minVersion': minVersion,
            'forced': true,
          };
        }
        return null;
      }

      await prefs.setInt(_keyLastCheck, now);

      final docRef = FirebaseFirestore.instance.doc(firestoreDocPath);
      final doc = await docRef.get();
      if (!doc.exists) return null;

      final data = doc.data() ?? {};
      final minVersionStr = data['minVersion'] as String? ?? '';
      final updateAvailable = data['updateAvailable'] as bool? ?? false;

      await prefs.setBool(_keyUpdateAvailable, updateAvailable);
      await prefs.setString(_keyMinVersion, minVersionStr);

      if (updateAvailable && minVersionStr.isNotEmpty) {
        final current = Version.parse(appVersion);
        final minimum = Version.parse(minVersionStr);
        if (current < minimum) {
          return {
            'updateAvailable': true,
            'minVersion': minVersionStr,
            'forced': true,
            'currentVersion': appVersion,
            'minVersionStr': minVersionStr,
          };
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkUpdateRemote() async {
    if (kIsWeb) return null;
    try {
      final response = await http.get(
        Uri.parse('https://prices-update-439714.uc.r.appspot.com/version'),
      );
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return Map<String, dynamic>.from(
        decoded['data'] ?? {},
      );
    } catch (_) {
      return null;
    }
  }

  bool isUpdateRequired(String minVersion) {
    final current = Version(appVersion);
    final minimum = Version(minVersion);
    return current < minimum;
  }
}

class Version implements Comparable<Version> {
  final int major;
  final int minor;
  final int patch;

  Version(String version)
      : major = int.parse(version.split('+').first.split('.')[0]),
        minor = int.parse(version.split('+').first.split('.')[1]),
        patch = int.parse(version.split('+').first.split('.')[2]);

  factory Version.parse(String version) => Version(version);

  @override
  int compareTo(Version other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator <(Version other) => compareTo(other) < 0;

  @override
  String toString() => '$major.$minor.$patch';
}