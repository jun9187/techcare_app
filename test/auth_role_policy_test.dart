import 'package:flutter_test/flutter_test.dart';
import 'package:techcare_app/services/auth_service.dart';

void main() {
  group('AuthRolePolicy', () {
    test('allows an admin account to enter the admin experience', () {
      expect(
        AuthRolePolicy.resolve(storedRole: 'admin', selectedRole: 'admin'),
        'admin',
      );
    });

    test('allows an admin account to enter the student experience', () {
      expect(
        AuthRolePolicy.resolve(storedRole: 'admin', selectedRole: 'student'),
        'student',
      );
    });

    test('allows a student account to enter the student experience', () {
      expect(
        AuthRolePolicy.resolve(storedRole: 'student', selectedRole: 'student'),
        'student',
      );
    });

    test('blocks a student account from the admin experience', () {
      expect(
        () => AuthRolePolicy.resolve(
          storedRole: 'student',
          selectedRole: 'admin',
        ),
        throwsA(
          isA<AuthRoleException>().having(
            (error) => error.message,
            'message',
            contains('does not have admin access'),
          ),
        ),
      );
    });

    test('normalizes stored and selected role values', () {
      expect(
        AuthRolePolicy.resolve(
          storedRole: ' ADMIN ',
          selectedRole: ' Student ',
        ),
        'student',
      );
    });
  });
}
