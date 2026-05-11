import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/inventory_item.dart';
import '../../services/inventory_service.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../models/cart_item.dart';
import 'inventory_item_form_screen.dart';

const Color _backgroundDark = Color(0xFF0F0F0F);
const Color _cardGrey = Color(0xFF1B1B1B);
const Color _utmMaroon = Color(0xFF800000);

class InventoryItemDetailScreen extends StatefulWidget {
  const InventoryItemDetailScreen({
    super.key,
    required this.item,
    required this.inventoryService,
  });

  final InventoryItem item;
  final InventoryService inventoryService;

  @override
  State<InventoryItemDetailScreen> createState() => _InventoryItemDetailScreenState();
}

class _InventoryItemDetailScreenState extends State<InventoryItemDetailScreen> {
  late InventoryItem _item;
  int quantity = 1;
  final isAdmin = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _editItem() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryItemFormScreen(
          inventoryService: widget.inventoryService,
          item: _item,
        ),
      ),
    );

    if (updated == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove ${_item.name} from the inventory collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.inventoryService.deleteItem(_item.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete item: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _backgroundDark,
        title: Text(_item.name),
        actions: [
          if (isAdmin) ...[
            IconButton(
              onPressed: _editItem,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: _deleteItem,
              icon: const Icon(Icons.delete_outline),
            ),
          ]
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardGrey,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _ItemImage(imageUrl: _item.imageUrl, size: 180)),
                const SizedBox(height: 20),
                Text(
                  _item.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(text: _item.category),
                    if (_item.subCategory.isNotEmpty) _InfoPill(text: _item.subCategory),
                  ],
                ),
                const SizedBox(height: 20),
                _FieldRow(label: 'Code', value: _item.code),
                _FieldRow(label: 'Name', value: _item.name),
                _FieldRow(label: 'Location', value: _item.location),
                _FieldRow(label: 'Quantity', value: '${_item.quantity}'),
                const SizedBox(height: 14),
                const Text(
                  'Description',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  _item.description,
                  style: const TextStyle(color: Colors.white, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: () {
                  if (quantity > 1) {
                    setState(() => quantity--);
                  }
                },
              ),
              Text(
                quantity.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  setState(() => quantity++);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () {
              context.read<CartCubit>().addItem(
                CartItem(
                  id: widget.item.id,
                  name: widget.item.name ?? 'Unknown',
                  image: widget.item.imageUrl,
                  code: widget.item.code ?? '',
                  quantity: quantity,
                ),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Added to cart")),
              );
            },
            child: const Text(
              "Add to Cart",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({
    required this.imageUrl,
    this.size = 96,
  });

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: size,
        width: size,
        color: Colors.white,
        child: imageUrl.isEmpty
            ? const Icon(Icons.inventory_2_outlined, size: 48, color: _utmMaroon)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: _utmMaroon,
                ),
              ),
      ),
    );
  }
}
