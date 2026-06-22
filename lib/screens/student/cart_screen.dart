import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../models/cart_item.dart';
import '../../services/rental_request_service.dart';

const Color _backgroundDark = Color(0xFF0F0F0F);
const Color _cardGrey = Color(0xFF1B1B1B);
const Color _utmMaroon = Color(0xFF800000);

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final RentalRequestService _requestService = RentalRequestService();
  bool _isSubmitting = false;

  Future<void> _submitRequest(List<CartItem> cartItems) async {
    final state = context.read<AuthBloc>().state;
    if (state is! Authenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login again.')));
      return;
    }

    if (cartItems.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final referenceId = await _requestService.submitRequest(
        requesterUid: state.uid,
        cartItems: cartItems,
      );

      if (!mounted) return;
      context.read<CartCubit>().clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request submitted: $referenceId')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit request: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = BlocBuilder<CartCubit, List<CartItem>>(
      builder: (context, cartItems) {
        if (cartItems.isEmpty) {
          return const _EmptyCartState();
        }

        final totalUnits = cartItems.fold<int>(
          0,
          (total, item) => total + item.quantity,
        );

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CartItemCard(
                      item: item,
                      isBusy: _isSubmitting,
                      onDecrease: () =>
                          context.read<CartCubit>().decreaseQty(item.id),
                      onIncrease: (item.isConsumable ? item.quantity >= 9999 : item.quantity >= item.maxQuantity)
                          ? null
                          : () =>
                                context.read<CartCubit>().increaseQty(item.id),
                      onRemove: () =>
                          context.read<CartCubit>().removeItem(item.id),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                decoration: const BoxDecoration(
                  color: _cardGrey,
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total Items',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        Text(
                          '$totalUnits unit(s)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _utmMaroon,
                          disabledBackgroundColor: Colors.white12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitRequest(cartItems),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Request',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    if (widget.embedded) {
      return ColoredBox(color: _backgroundDark, child: content);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: _backgroundDark,
      ),
      backgroundColor: _backgroundDark,
      body: content,
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.isBusy,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final CartItem item;
  final bool isBusy;
  final VoidCallback onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 58,
              height: 58,
              color: Colors.white,
              child: item.image != null && item.image!.isNotEmpty
                  ? Image.network(
                      item.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.inventory_2_outlined,
                        color: _utmMaroon,
                      ),
                    )
                  : const Icon(Icons.inventory_2_outlined, color: _utmMaroon),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!item.isConsumable) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Available: ${item.maxQuantity}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QtyButton(
                      icon: Icons.remove_rounded,
                      onTap: isBusy || item.quantity <= 1 ? null : onDecrease,
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add_rounded,
                      onTap: isBusy ? null : onIncrease,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
            onPressed: isBusy ? null : onRemove,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon, size: 18),
        color: Colors.white,
        disabledColor: Colors.white24,
        onPressed: onTap,
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Cart is empty',
        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
      ),
    );
  }
}
