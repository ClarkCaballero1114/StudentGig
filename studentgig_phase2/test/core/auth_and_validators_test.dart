import 'package:flutter_test/flutter_test.dart';
import 'package:studentgig/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty input', () {
      expect(Validators.email(''), isNotNull);
    });

    test('rejects input without @', () {
      expect(Validators.email('ana.example.com'), isNotNull);
    });

    test('accepts a valid address with surrounding spaces', () {
      expect(Validators.email('  ana@school.edu '), isNull);
    });
  });

  group('Validators.newPassword', () {
    test('rejects passwords shorter than 8 characters', () {
      expect(Validators.newPassword('short12'), isNotNull);
    });

    test('accepts passwords of 8 or more characters', () {
      expect(Validators.newPassword('longenough'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects mismatched passwords', () {
      expect(Validators.confirmPassword('abcdefgh', 'abcdefgz'), isNotNull);
    });

    test('accepts matching passwords', () {
      expect(Validators.confirmPassword('abcdefgh', 'abcdefgh'), isNull);
    });
  });
}
