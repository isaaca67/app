import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_cov_dark_mobile_login/features/auth/utils/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('acepta datos válidos para crear una cuenta', () {
      expect(AuthValidators.name('Aron Ortiz'), isNull);
      expect(AuthValidators.email('aron@example.com'), isNull);
      expect(AuthValidators.password('secreto123'), isNull);
    });

    test('rechaza correo incompleto', () {
      expect(AuthValidators.email('aron@'), isNotNull);
      expect(AuthValidators.email('aron.com'), isNotNull);
    });

    test('rechaza nombre y contraseña demasiado cortos', () {
      expect(AuthValidators.name('A'), isNotNull);
      expect(AuthValidators.password('123'), isNotNull);
    });
  });
}
