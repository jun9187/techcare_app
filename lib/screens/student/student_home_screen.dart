import 'package:flutter/material.dart';
import 'student_inventory_screen.dart';
import 'cart_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Student Home"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _card(
              context,
              "Browse Items",
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentInventoryScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _card(
              context,
              "My Requests",
              () {
                Navigator.pushNamed(context, '/requests');
              },
            ),
            const SizedBox(height: 20),
            _card(
              context,
              "My Cart",
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CartScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
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