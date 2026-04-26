import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc(this.authService) : super(AuthInitial()) {
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final result = await authService.signInWithEmail(event.email, event.password);
        emit(Authenticated(result.user!.uid));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final result = await authService.registerWithEmail(
          email: event.email,
          password: event.password,
          name: event.name,
          matricNumber: event.matricNumber,
        );
        emit(Authenticated(result.user!.uid));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<GoogleLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final result = await authService.signInWithGoogle();
        if (result != null) {
          emit(Authenticated(result.user!.uid));
        } else {
          emit(Unauthenticated());
        }
      } catch (e) {
        emit(AuthError("Google Sign-In failed or cancelled."));
      }
    });

    on<LogoutRequested>((event, emit) async {
      await authService.signOut();
      emit(Unauthenticated());
    });
  }
}
