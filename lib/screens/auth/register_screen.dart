import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

// Brand Constants
const Color utmMaroon = Color(0xFF800000);
const Color goldHighlight = Color(0xFFFFD700);
const Color backgroundDark = Color(0xFF0F0F0F);
const Color cardGrey = Color(0xFF1E1E1E);

class RegisterScreen extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _matricController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.pushReplacementNamed(context, '/profile');
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
                const Text(
                  "TechCare",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 40),
                const Text(
                  "New User",
                  style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                _buildModernField("Full Name", Icons.person_outline_rounded, controller: _nameController),
                const SizedBox(height: 15),
                _buildModernField("Email Address", Icons.alternate_email_rounded, controller: _emailController),
                const SizedBox(height: 15),
                _buildModernField("Matric Number", Icons.badge_outlined, controller: _matricController),
                const SizedBox(height: 15),
                _buildModernField("Password", Icons.lock_outline_rounded, obscure: true, controller: _passwordController),
                const SizedBox(height: 15),
                _buildModernField("Confirm Password", Icons.lock_reset_rounded, obscure: true, controller: _confirmPasswordController),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: utmMaroon,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    onPressed: () {
                      if (_passwordController.text != _confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Passwords do not match!")),
                        );
                        return;
                      }
                      
                      if (_passwordController.text.length < 6) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Password should be at least 6 characters.")),
                        );
                        return;
                      }

                      context.read<AuthBloc>().add(RegisterRequested(
                            email: _emailController.text,
                            password: _passwordController.text,
                            name: _nameController.text,
                            matricNumber: _matricController.text,
                          ));
                    },
                    child: const Text(
                      "Create Account",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Modern Google Button
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    onPressed: () => context.read<AuthBloc>().add(GoogleLoginRequested()),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(
                          'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                          height: 24,
                          width: 24,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: Text(
                            "Sign up with Google",
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: "Sign In",
                            style: TextStyle(color: goldHighlight, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernField(String hint, IconData icon, {bool obscure = false, required TextEditingController controller}) {
    return Container(
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          icon: Icon(icon, color: Colors.white38, size: 22),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
