import 'package:flutter/material.dart';

const Color _backgroundDark = Color(0xFF0F0F0F);
const Color _cardGrey = Color(0xFF1B1B1B);
const Color _utmMaroon = Color(0xFF800000);

class AdminRequestsPlaceholderScreen extends StatelessWidget {
  const AdminRequestsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _backgroundDark,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardGrey,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rental Requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Coming next sprint',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...const [
            _PlaceholderTaskTile(
              title: 'Pending approvals',
              icon: Icons.pending_actions_outlined,
            ),
            _PlaceholderTaskTile(
              title: 'Borrowed item tracking',
              icon: Icons.assignment_return_outlined,
            ),
            _PlaceholderTaskTile(
              title: 'Status confirmation',
              icon: Icons.fact_check_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaceholderTaskTile extends StatelessWidget {
  const _PlaceholderTaskTile({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: _utmMaroon.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
