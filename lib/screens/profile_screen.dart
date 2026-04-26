import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("User Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF800000),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF800000)));
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Error loading profile or no data found.", style: TextStyle(color: Colors.white)),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.person, size: 70, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 30),
                
                _buildInfoCard("Full Name", userData['name'] ?? "N/A"),
                _buildInfoCard("Email Address", userData['email'] ?? "N/A"),
                _buildInfoCard("Matric Number", userData['matricNumber'] ?? "N/A"),
                
                const SizedBox(height: 40),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Welcome back to TechCare! Your account is now fully integrated with our services.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
