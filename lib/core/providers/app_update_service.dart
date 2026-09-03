import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService extends ChangeNotifier {
  static const String _configCollection = 'config';
  static const String _appVersionDoc = 'app_version';

  bool _isChecking = false;
  bool _updateAvailable = false;
  String _latestVersion = '';
  String _currentVersion = '';
  String _downloadUrl = '';
  String _releaseNotes = '';

  bool get isChecking => _isChecking;
  bool get updateAvailable => _updateAvailable;
  String get latestVersion => _latestVersion;
  String get currentVersion => _currentVersion;
  String get downloadUrl => _downloadUrl;
  String get releaseNotes => _releaseNotes;

  late final Future<void> _ready;

  AppUpdateService() {
    _ready = _initCurrentVersion();
  }

  Future<void> _initCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  Future<void> checkForUpdate() async {
    if (_isChecking) return;
    await _ready;

    _isChecking = true;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance
          .collection(_configCollection)
          .doc(_appVersionDoc)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _latestVersion = data['latest_version'] ?? _currentVersion;
        _downloadUrl = data['download_url'] ?? '';
        _releaseNotes = data['release_notes'] ?? '';

        _updateAvailable = _isNewerVersion(_latestVersion, _currentVersion);
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('+').first.split('.').map(int.parse).toList();
      final currentParts = current.split('+').first.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openUpdateUrl() async {
    if (_downloadUrl.isNotEmpty) {
      final uri = Uri.parse(_downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void reset() {
    _updateAvailable = false;
    _latestVersion = '';
    _downloadUrl = '';
    _releaseNotes = '';
    notifyListeners();
  }
}