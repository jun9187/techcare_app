import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;
  late final StreamSubscription<User?> _authSubscription;
  bool _isInteractiveLoginInProgress = false;

  AuthBloc(this.authService) : super(AuthInitial()) {
    on<AuthStatusChanged>((event, emit) {
      if (!event.isAuthenticated || event.uid == null || event.role == null) {
        emit(Unauthenticated());
        return;
      }

      emit(Authenticated(event.uid!, event.role!));
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      _isInteractiveLoginInProgress = true;
      try {
        final result = await authService.signInWithEmail(
          event.email,
          event.password,
          event.role,
        );
        emit(Authenticated(result.credential.user!.uid, result.role));
      } catch (e) {
        emit(AuthError(e.toString()));
      } finally {
        _isInteractiveLoginInProgress = false;
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
          role: event.role,
        );
        emit(Authenticated(result.credential.user!.uid, result.role));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<GoogleLoginRequested>((event, emit) async {
      emit(AuthLoading());
      _isInteractiveLoginInProgress = true;
      try {
        final result = await authService.signInWithGoogle(event.role);
        if (result != null) {
          emit(Authenticated(result.credential.user!.uid, result.role));
        } else {
          emit(Unauthenticated());
        }
      } on AuthRoleException catch (e) {
        emit(AuthError(e.message));
      } catch (e) {
        emit(AuthError('Google Sign-In failed. Please try again.'));
      } finally {
        _isInteractiveLoginInProgress = false;
      }
    });

    on<LogoutRequested>((event, emit) async {
      await authService.signOut();
      emit(Unauthenticated());
    });

    _authSubscription = authService.user.listen((user) async {
      if (_isInteractiveLoginInProgress) {
        return;
      }

      if (user == null) {
        add(AuthStatusChanged.unauthenticated());
        return;
      }

      try {
        final role = await authService.getActiveRole(user);
        add(AuthStatusChanged.authenticated(uid: user.uid, role: role));
      } catch (_) {
        add(AuthStatusChanged.unauthenticated());
      }
    });
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }
}
