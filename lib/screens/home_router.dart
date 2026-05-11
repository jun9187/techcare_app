import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import 'admin/admin_shell_screen.dart';
import 'auth/login_screen.dart';
import 'profile_screen.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;

    if (state is AuthInitial || state is AuthLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state is Authenticated && state.role == 'admin') {
      return const AdminShellScreen();
    }

    if (state is Authenticated) {
      return const ProfileScreen();
    }

    return const LoginScreen();
  }
}
