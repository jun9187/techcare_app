import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import 'user_tile.dart';

const Color _utmMaroon = Color(0xFF800000);
const Color _goldHighlight = Color(0xFFFFD700);
const Color _backgroundDark = Color(0xFF0F0F0F);
const Color _cardGrey = Color(0xFF1B1B1B);

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({
    super.key,
    required this.user,
    required this.authService,
  });

  final Map<String, dynamic> user;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final uid = user['id']?.toString() ?? '';

    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _backgroundDark,
        title: const Text('User Details'),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: authService.streamUser(uid),
        initialData: user,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load user: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          final currentUser = snapshot.data;
          if (currentUser == null) {
            return const Center(
              child: Text(
                'This user no longer exists.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return _UserDetailContent(
            user: currentUser,
            authService: authService,
          );
        },
      ),
    );
  }
}

class _UserDetailContent extends StatefulWidget {
  const _UserDetailContent({required this.user, required this.authService});

  final Map<String, dynamic> user;
  final AuthService authService;

  @override
  State<_UserDetailContent> createState() => _UserDetailContentState();
}

class _UserDetailContentState extends State<_UserDetailContent> {
  bool _isUpdatingRole = false;

  Future<void> _changeRole(String currentRole) async {
    final newRole = currentRole == 'admin' ? 'student' : 'admin';
    final formattedRole = '${newRole[0].toUpperCase()}${newRole.substring(1)}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardGrey,
        title: const Text(
          'Change user role?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Change this user’s role to $formattedRole?',
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
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _utmMaroon),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUpdatingRole = true);
    try {
      await widget.authService.updateUserRole(
        uid: widget.user['id']?.toString() ?? '',
        newRole: newRole,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role changed to $formattedRole.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to change role: $error')));
    } finally {
      if (mounted) {
        setState(() => _isUpdatingRole = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.user['id']?.toString() ?? '';
    final name = _textValue(widget.user['name'], fallback: 'Unknown User');
    final role = _textValue(
      widget.user['role'],
      fallback: 'student',
    ).toLowerCase();
    final isAdmin = role == 'admin';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A0D0D), Color(0xFF8B1E1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                child: Icon(
                  isAdmin
                      ? Icons.admin_panel_settings_rounded
                      : Icons.school_rounded,
                  color: isAdmin ? _goldHighlight : Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              RoleBadge(role: role),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _RoleField(
          role: role,
          isLoading: _isUpdatingRole,
          onChangeRole: () => _changeRole(role),
        ),
        const SizedBox(height: 16),
        _DetailCard(
          children: [
            _DetailRow(
              icon: Icons.email_outlined,
              label: 'Email Address',
              value: _textValue(widget.user['email']),
            ),
            _DetailRow(
              icon: Icons.badge_outlined,
              label: 'Matric Number',
              value: _textValue(widget.user['matricNumber']),
            ),
            _DetailRow(
              icon: Icons.school_outlined,
              label: 'Faculty',
              value: _textValue(widget.user['faculty']),
            ),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Account Created',
              value: _formatTimestamp(widget.user['createdAt']),
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DetailCard(
          children: [
            _DetailRow(
              icon: Icons.fingerprint_rounded,
              label: 'User ID',
              value: uid.isEmpty ? 'Not available' : uid,
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }

  static String _textValue(dynamic value, {String fallback = 'Not provided'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String _formatTimestamp(dynamic value) {
    if (value is! Timestamp) {
      return 'Not available';
    }

    final date = value.toDate().toLocal();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _RoleField extends StatelessWidget {
  const _RoleField({
    required this.role,
    required this.isLoading,
    required this.onChangeRole,
  });

  final String role;
  final bool isLoading;
  final VoidCallback onChangeRole;

  @override
  Widget build(BuildContext context) {
    final formattedRole = role == 'admin' ? 'Admin' : 'Student';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: _utmMaroon.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.manage_accounts_rounded,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Role',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedRole,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: isLoading ? null : onChangeRole,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: _utmMaroon),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Change'),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: _utmMaroon.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white70, size: 20),
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
                    SelectableText(
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
