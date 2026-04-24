import 'package:flutter/material.dart';

const Color utmMaroon = Color(0xFF800000);
const Color goldHighlight = Color(0xFFFFD700);
const Color backgroundDark = Color(0xFF0F0F0F);
const Color cardGrey = Color(0xFF1E1E1E);

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: utmMaroon.withValues(alpha: 0.15),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // TechCare Brand Title
                  Row(
                    children: [
                      const Icon(Icons.build_circle_outlined, color: goldHighlight, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        "TechCare",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: utmMaroon.withValues(alpha: 0.5),
                              blurRadius: 10,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  // "Log In" / "Sign Up" Header
                  Text(
                    _isLogin ? "Log In" : "Sign Up",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Large Prototype Heading
                  Text(
                    _isLogin ? "Welcome back!" : "Create Account",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildModernField("Email Address", Icons.alternate_email_rounded),
                  const SizedBox(height: 20),
                  _buildModernField("Password", Icons.lock_outline_rounded, obscure: true),

                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: goldHighlight, fontSize: 14),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Primary Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: utmMaroon,
                        elevation: 8,
                        shadowColor: utmMaroon.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        // Trigger AuthBloc for login/register
                      },
                      child: Text(
                        _isLogin ? "Log In" : "Sign Up",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Toggle Switch
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _isLogin = !_isLogin),
                      child: RichText(
                        text: TextSpan(
                          text: _isLogin ? "New User? " : "Existing User? ",
                          style: const TextStyle(color: Colors.white54, fontSize: 15),
                          children: [
                            TextSpan(
                              text: _isLogin ? "Create Account" : "Log In",
                              style: const TextStyle(
                                color: goldHighlight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernField(String hint, IconData icon, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          icon: Icon(icon, color: Colors.white54, size: 22),
          border: InputBorder.none,
        ),
      ),
    );
  }
}