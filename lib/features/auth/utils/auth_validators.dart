import 'package:stitch_cov_dark_mobile_login/core/constants/app_constants.dart';
import 'package:stitch_cov_dark_mobile_login/core/constants/app_strings.dart';

class AuthValidators {
  AuthValidators._();

  static String? name(String? value) =>
      value == null || value.trim().length < AppConstants.nameMinLength
      ? AppStrings.nameTooShort
      : null;

  static String? email(String? value) {
    final normalized = value?.trim() ?? '';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized);
    return valid ? null : AppStrings.invalidEmail;
  }

  static String? password(String? value) =>
      value == null || value.length < AppConstants.passwordMinLength
      ? AppStrings.passwordTooShort
      : null;
}
