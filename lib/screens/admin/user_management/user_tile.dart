import 'package:flutter/material.dart';

const Color utmMaroon = Color(0xFF800000);
const Color goldHighlight = Color(0xFFFFD700);
const Color backgroundDark = Color(0xFF0F0F0F);
const Color cardGrey = Color(0xFF1B1B1B);

class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.user, required this.onTap});

  final Map<String, dynamic> user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = (user['name'] as String?) ?? 'Unknown';
    final email = (user['email'] as String?) ?? '';
    final role = (user['role'] as String?) ?? 'student';
    final isAdmin = role == 'admin';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              RoleBadge(role: role),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role.toLowerCase() == 'admin';

    return Container(
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
    );
  }
}
