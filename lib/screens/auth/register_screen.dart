import 'package:flutter/material.dart';

// Brand Constants
const Color utmMaroon = Color(0xFF800000);
const Color goldHighlight = Color(0xFFFFD700);
const Color backgroundDark = Color(0xFF0F0F0F);
const Color cardGrey = Color(0xFF1E1E1E);

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sign Up",
                style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                "Join the Owls",
                style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Sprint 1 Fields: Registration requires more detail
              _buildModernField("Full Name", Icons.person_outline_rounded),
              const SizedBox(height: 15),
              _buildModernField("UTM Email Address", Icons.alternate_email_rounded),
              const SizedBox(height: 15),
              _buildModernField("Matric Number (e.g., A22EC...)", Icons.badge_outlined),
              const SizedBox(height: 15),
              _buildModernField("Password", Icons.lock_outline_rounded, obscure: true),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: utmMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    // Navigate to 2FA TAC Verification
                  },
                  child: const Text(
                    "Create Account",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
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