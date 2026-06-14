import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';

const Color utmMaroon = Color(0xFF800000);
const Color goldHighlight = Color(0xFFFFD700);
const Color backgroundDark = Color(0xFF0F0F0F);
const Color cardGrey = Color(0xFF1B1B1B);

class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.user, required this.authService});

  final Map<String, dynamic> user;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final name = (user['name'] as String?) ?? 'Unknown';
    final email = (user['email'] as String?) ?? '';
    final role = (user['role'] as String?) ?? 'student';
    final uid = user['id'] as String;
    final isAdmin = role == 'admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isAdmin
                ? utmMaroon.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
            child: Icon(
              isAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.school_rounded,
              color: isAdmin ? goldHighlight : Colors.white54,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          RoleBadgeToggle(
            uid: uid,
            currentRole: role,
            authService: authService,
          ),
        ],
      ),
    );
  }
}

class RoleBadgeToggle extends StatefulWidget {
  const RoleBadgeToggle({
    super.key,
    required this.uid,
    required this.currentRole,
    required this.authService,
  });

  final String uid;
  final String currentRole;
  final AuthService authService;

  @override
  State<RoleBadgeToggle> createState() => _RoleBadgeToggleState();
}

class _RoleBadgeToggleState extends State<RoleBadgeToggle> {
  bool _loading = false;

  Future<void> _toggleRole() async {
    final newRole = widget.currentRole == 'admin' ? 'student' : 'admin';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardGrey,
        title: const Text(
          'Change role?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Set this user as ${newRole[0].toUpperCase()}${newRole.substring(1)}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Confirm',
              style: TextStyle(
                color: newRole == 'admin' ? goldHighlight : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await widget.authService.updateUserRole(
        uid: widget.uid,
        newRole: newRole,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update role: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentRole == 'admin';

    if (_loading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return GestureDetector(
      onTap: _toggleRole,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isAdmin
              ? utmMaroon.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAdmin
                ? goldHighlight.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          isAdmin ? 'Admin' : 'Student',
          style: TextStyle(
            color: isAdmin ? goldHighlight : Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
