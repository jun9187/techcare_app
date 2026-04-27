import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _matricController = TextEditingController();
  final TextEditingController _facultyController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _matricController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text,
        'matricNumber': _matricController.text,
        'faculty': _facultyController.text,
      });
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("User Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF800000),
        elevation: 0,
        centerTitle: true,
        leading: _isEditing 
          ? IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(() => _isEditing = false),
            )
          : null,
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text("Edit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF800000)));
          }

          if (state is Authenticated) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(state.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF800000)));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text("Profile not found", style: TextStyle(color: Colors.white)),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                
                if (!_isEditing) {
                  _nameController.text = userData['name'] ?? "";
                  _matricController.text = userData['matricNumber'] ?? "";
                  _facultyController.text = userData['faculty'] ?? "";
                }

                return _buildProfileContent(context, userData, state.uid);
              },
            );
          }

          if (state is AuthInitial) {
             return const Center(child: Text("Initializing...", style: TextStyle(color: Colors.white)));
          }

          return const Center(child: Text("Please login to view profile", style: TextStyle(color: Colors.white)));
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, Map<String, dynamic> data, String uid) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(data['name'] ?? 'User', uid),
          const SizedBox(height: 20),
          _buildInfoCard(
            label: "Full Name",
            value: data['name'] ?? "N/A",
            icon: Icons.person_outline,
            controller: _nameController,
            isEditable: true,
          ),
          _buildInfoCard(
            label: "Email Address",
            value: data['email'] ?? "N/A",
            icon: Icons.email_outlined,
            isEditable: false,
          ),
          _buildInfoCard(
            label: "Matric Number",
            value: data['matricNumber'] ?? "N/A",
            icon: Icons.badge_outlined,
            controller: _matricController,
            isEditable: true,
          ),
          _buildInfoCard(
            label: "Faculty",
            value: data['faculty'] ?? "Not Specified",
            icon: Icons.school_outlined,
            controller: _facultyController,
            isEditable: true,
          ),
          const SizedBox(height: 30),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF800000),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () => _updateProfile(uid),
                      child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text("Cancel", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF800000)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => setState(() => _isEditing = true),
                  child: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String uid) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 120,
          decoration: const BoxDecoration(
            color: Color(0xFF800000),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        Column(
          children: [
            const SizedBox(height: 40),
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F0F0F),
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF1E1E1E),
                    child: Icon(Icons.person, size: 60, color: Colors.white70),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () {
                      // Logic to change profile picture
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Change profile picture feature coming soon!")),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!_isEditing)
              Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
    TextEditingController? controller,
    required bool isEditable,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF800000), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                const SizedBox(height: 4),
                if (_isEditing && isEditable && controller != null)
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                      hintText: "Enter value",
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                  )
                else
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
