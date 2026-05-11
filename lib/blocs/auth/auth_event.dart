abstract class AuthEvent {}

class AuthStatusChanged extends AuthEvent {
  final bool isAuthenticated;
  final String? uid;
  final String? role;

  AuthStatusChanged.unauthenticated()
      : isAuthenticated = false,
        uid = null,
        role = null;

  AuthStatusChanged.authenticated({
    required this.uid,
    required this.role,
  }) : isAuthenticated = true;
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String role;

  LoginRequested(this.email, this.password, this.role);
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String matricNumber;
  final String role;

  RegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.matricNumber,
    this.role = 'student',
  });
}

class GoogleLoginRequested extends AuthEvent {
  final String role;

  GoogleLoginRequested({this.role = 'student'});
}

class LogoutRequested extends AuthEvent {}
