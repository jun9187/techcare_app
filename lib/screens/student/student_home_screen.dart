import 'package:flutter/material.dart';

import 'cart_screen.dart';
import 'student_inventory_screen.dart';
import 'student_requests_screen.dart';

const Color _backgroundDark = Color(0xFF0F0F0F);
const Color _cardGrey = Color(0xFF1B1B1B);
const Color _utmMaroon = Color(0xFF800000);

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({
    super.key,
    this.embedded = false,
    this.onOpenInventory,
    this.onOpenRequests,
    this.onOpenCart,
  });

  final bool embedded;
  final VoidCallback? onOpenInventory;
  final VoidCallback? onOpenRequests;
  final VoidCallback? onOpenCart;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF4A0D0D), Color(0xFF8B1E1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Home',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'TechCare Equipment Rental',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _QuickActionCard(
          title: 'Browse Items',
          icon: Icons.inventory_2_rounded,
          buttonLabel: 'View Items',
          onTap: () => _openInventory(context),
        ),
        const SizedBox(height: 12),
        _QuickActionCard(
          title: 'My Requests',
          icon: Icons.assignment_outlined,
          buttonLabel: 'View Requests',
          onTap: () => _openRequests(context),
        ),
        const SizedBox(height: 12),
        _QuickActionCard(
          title: 'My Cart',
          icon: Icons.shopping_cart_rounded,
          buttonLabel: 'View Cart',
          onTap: () => _openCart(context),
        ),
      ],
    );

    if (embedded) {
      return ColoredBox(color: _backgroundDark, child: content);
    }

    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        title: const Text('Student Home'),
        backgroundColor: _backgroundDark,
      ),
      body: content,
    );
  }

  void _openInventory(BuildContext context) {
    if (embedded && onOpenInventory != null) {
      onOpenInventory!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentInventoryScreen()),
    );
  }

  void _openRequests(BuildContext context) {
    if (embedded && onOpenRequests != null) {
      onOpenRequests!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentRequestsScreen()),
    );
  }

  void _openCart(BuildContext context) {
    if (embedded && onOpenCart != null) {
      onOpenCart!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: _utmMaroon.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
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
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _utmMaroon,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(buttonLabel),
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
