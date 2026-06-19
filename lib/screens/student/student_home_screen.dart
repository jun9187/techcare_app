import 'package:flutter/material.dart';

import 'cart_screen.dart';
import 'student_inventory_screen.dart';
import 'student_requests_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({
    super.key,
    this.embedded = false,
    this.onOpenInventory,
    this.onOpenCart,
  });

  final bool embedded;
  final VoidCallback? onOpenInventory;
  final VoidCallback? onOpenCart;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _card(
            context,
            'Browse Items',
            () {
              if (embedded && onOpenInventory != null) {
                onOpenInventory!.call();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentInventoryScreen(),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 20),
          _card(
            context,
            'My Requests',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentRequestsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _card(
            context,
            'My Cart',
            () {
              if (embedded && onOpenCart != null) {
                onOpenCart!.call();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CartScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );

    if (embedded) {
      return ColoredBox(color: Colors.black, child: content);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Student Home'),
        backgroundColor: Colors.black,
      ),
      body: content,
    );
  }

  Widget _card(BuildContext context, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
