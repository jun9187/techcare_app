abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String matricNumber;

  RegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.matricNumber,
  });
}

class GoogleLoginRequested extends AuthEvent {}

class LogoutRequested extends AuthEvent {}
