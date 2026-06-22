import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

const Color _backgroundDark = Color(0xFF0F0F0F);
const Color _cardGrey = Color(0xFF1B1B1B);
const Color _utmMaroon = Color(0xFF800000);
const Color _goldHighlight = Color(0xFFFFD700);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _matricController = TextEditingController();
  final _facultyController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  String? _editingUid;

  @override
  void dispose() {
    _nameController.dispose();
    _matricController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

  void _populateControllers(
    String uid,
    Map<String, dynamic> data, {
    bool force = false,
  }) {
    if (!force && _isEditing && _editingUid == uid) {
      return;
    }

    _editingUid = uid;
    _nameController.text = _text(data['name']);
    _matricController.text = _text(data['matricNumber']);
    _facultyController.text = _text(data['faculty']);
  }

  void _startEditing(String uid, Map<String, dynamic> data) {
    _populateControllers(uid, data, force: true);
    setState(() => _isEditing = true);
  }

  void _cancelEditing(String uid, Map<String, dynamic> data) {
    FocusScope.of(context).unfocus();
    _populateControllers(uid, data, force: true);
    setState(() => _isEditing = false);
  }

  Future<void> _updateProfile(String uid) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Full name cannot be empty.', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': name,
        'matricNumber': _matricController.text.trim(),
        'faculty': _facultyController.text.trim(),
      });

      if (!mounted) return;
      setState(() => _isEditing = false);
      _showMessage('Profile updated successfully.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Unable to update profile: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade800 : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: _backgroundDark,
              title: const Text(
                'My Profile',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                IconButton(
                  tooltip: 'Logout',
                  onPressed: _isSaving
                      ? null
                      : () {
                          context.read<AuthBloc>().add(LogoutRequested());
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            )
          : null,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial || state is AuthLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _utmMaroon),
            );
          }

          if (state is! Authenticated) {
            return const _ProfileMessage(
              icon: Icons.lock_outline_rounded,
              message: 'Please sign in to view your profile.',
            );
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(state.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: _utmMaroon),
                );
              }

              if (snapshot.hasError) {
                return _ProfileMessage(
                  icon: Icons.error_outline_rounded,
                  message: 'Unable to load profile: ${snapshot.error}',
                );
              }

              final data = snapshot.data?.data();
              if (data == null) {
                return const _ProfileMessage(
                  icon: Icons.person_off_outlined,
                  message: 'Profile information was not found.',
                );
              }

              _populateControllers(state.uid, data);
              return _buildProfileContent(state.uid, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileContent(String uid, Map<String, dynamic> data) {
    final name = _displayText(data['name'], fallback: 'User');
    final email = _displayText(data['email']);
    final role = _displayText(data['role'], fallback: 'student').toLowerCase();

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      child: Column(
        children: [
          _ProfileHeader(name: name, email: email, role: role),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Account Information',
            children: [
              _ProfileField(
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                value: name,
                controller: _nameController,
                isEditing: _isEditing,
              ),
              _ProfileField(
                label: 'Email Address',
                icon: Icons.email_outlined,
                value: email,
                isEditing: false,
              ),
              _ProfileField(
                label: 'Matric Number',
                icon: Icons.badge_outlined,
                value: _displayText(data['matricNumber']),
                controller: _matricController,
                isEditing: _isEditing,
              ),
              _ProfileField(
                label: 'Faculty',
                icon: Icons.school_outlined,
                value: _displayText(data['faculty']),
                controller: _facultyController,
                isEditing: _isEditing,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_isEditing)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => _cancelEditing(uid, data),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      minimumSize: const Size.fromHeight(54),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : () => _updateProfile(uid),
                    style: FilledButton.styleFrom(
                      backgroundColor: _utmMaroon,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _startEditing(uid, data),
                style: FilledButton.styleFrom(
                  backgroundColor: _utmMaroon,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static String _displayText(
    dynamic value, {
    String fallback = 'Not provided',
  }) {
    final text = _text(value);
    return text.isEmpty ? fallback : text;
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A0D0D), Color(0xFF8B1E1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            child: Icon(
              isAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.person_rounded,
              size: 46,
              color: isAdmin ? _goldHighlight : Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isAdmin
                    ? _goldHighlight.withValues(alpha: 0.55)
                    : Colors.white24,
              ),
            ),
            child: Text(
              isAdmin ? 'Administrator' : 'Student',
              style: TextStyle(
                color: isAdmin ? _goldHighlight : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.icon,
    required this.value,
    required this.isEditing,
    this.controller,
    this.showDivider = true,
  });

  final String label;
  final IconData icon;
  final String value;
  final bool isEditing;
  final TextEditingController? controller;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: _utmMaroon.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white70, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (isEditing && controller != null)
                      TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Enter value',
                          hintStyle: TextStyle(color: Colors.white24),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: _goldHighlight),
                          ),
                        ),
                      )
                    else
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
      ],
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white38, size: 48),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
