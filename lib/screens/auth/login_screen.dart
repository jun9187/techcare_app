import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

const Color utmMaroon = Color(0xFF800000);
const Color goldHighlight = Color(0xFFFFD700);

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text("TechCare", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 40),
                const Text("Welcome back!", style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),

                // Custom Modern Fields (Placeholder for your styled widget)
                TextField(controller: _emailController, decoration: const InputDecoration(hintText: "UTM Email", hintStyle: TextStyle(color: Colors.white24))),
                const SizedBox(height: 20),
                TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(hintText: "Password", hintStyle: TextStyle(color: Colors.white24))),

                const SizedBox(height: 40),

                // Main Login Button
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: utmMaroon),
                    onPressed: () {
                      context.read<AuthBloc>().add(LoginRequested(_emailController.text, _passwordController.text));
                    },
                    child: const Text("Sign In", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),
                // Google Login Button
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: OutlinedButton(
                    onPressed: () => context.read<AuthBloc>().add(GoogleLoginRequested()),
                    child: const Text("Continue with Google", style: TextStyle(color: goldHighlight)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}