import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../models/cart_item.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = BlocBuilder<CartCubit, List<CartItem>>(
        builder: (context, cartItems) {
          if (cartItems.isEmpty) {
            return const Center(
              child: Text(
                "Cart is empty",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          item.image != null && (item.image as String).isNotEmpty
                              ? Image.network(
                                  item.image!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported, color: Colors.grey),
                                )
                              : const Icon(Icons.image_not_supported, color: Colors.grey, size: 60),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(color: Colors.white)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: Colors.white),
                                      onPressed: () {
                                        context.read<CartCubit>().decreaseQty(item.id);
                                      },
                                    ),
                                    Text(
                                      item.quantity.toString(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.white),
                                      onPressed: item.quantity >= item.maxQuantity
                                          ? null
                                          : () {
                                              context.read<CartCubit>().increaseQty(item.id);
                                            },
                                    ),
                                  ],
                                ),
                                Text(
                                  'Available: ${item.maxQuantity}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              context.read<CartCubit>().removeItem(item.id);
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              // 🔥 TOTAL + BUTTON
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "Total Items: ${cartItems.length}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Request submitted")),
                        );

                        context.read<CartCubit>().clearCart();
                      },
                      child: const Text("Submit Request"),
                    )
                  ],
                ),
              )
            ],
          );
        },
    );

    if (embedded) {
      return ColoredBox(color: Colors.black, child: content);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: content,
    );
  }
}
