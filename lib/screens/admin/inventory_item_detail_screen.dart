import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../blocs/cart/cart_cubit.dart';
import '../../models/cart_item.dart';
import '../../models/inventory_item.dart';
import '../../services/inventory_service.dart';
import '../student/cart_screen.dart';
import 'inventory_item_form_screen.dart';

const Color _backgroundDark = Color(0xFF0F0F0F);
const Color _cardGrey = Color(0xFF1B1B1B);
const Color _utmMaroon = Color(0xFF800000);

class InventoryItemDetailScreen extends StatefulWidget {
  const InventoryItemDetailScreen({
    super.key,
    required this.item,
    required this.inventoryService,
    this.isAdmin = false,
  });

  final InventoryItem item;
  final InventoryService inventoryService;
  final bool isAdmin;

  @override
  State<InventoryItemDetailScreen> createState() =>
      _InventoryItemDetailScreenState();
}

class _InventoryItemDetailScreenState extends State<InventoryItemDetailScreen> {
  late InventoryItem _item;
  late final TextEditingController _quantityController;
  late final FocusNode _quantityFocusNode;
  bool _isUpdatingQuantity = false;
  int _cartQuantity = 1;

  bool get _isCartQuantityAtLimit => !_item.isConsumable && _cartQuantity >= _item.availableAmount;

  bool get _hasPendingQuantityChange {
    final parsed = int.tryParse(_quantityController.text.trim());
    if (parsed == null) return false;
    return parsed.clamp(0, 9999) != _item.totalAmount;
  }

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _cartQuantity = _item.isConsumable ? 1 : (_item.availableAmount > 0 ? 1 : 0);
    _quantityController = TextEditingController(text: '${_item.totalAmount}');
    _quantityController.addListener(_handleQuantityDraftChanged);
    _quantityFocusNode = FocusNode();
  }

  void _handleQuantityDraftChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _adjustQuantity(int delta) async {
    final currentValue =
        int.tryParse(_quantityController.text.trim()) ?? _item.totalAmount;
    final nextValue = (currentValue + delta).clamp(0, 9999);
    if (nextValue == currentValue) return;

    _quantityController.value = TextEditingValue(
      text: '$nextValue',
      selection: TextSelection.collapsed(offset: '$nextValue'.length),
    );
  }

  Future<void> _submitQuantity() async {
    final parsed = int.tryParse(_quantityController.text.trim());
    if (parsed == null) {
      _quantityController.text = '${_item.totalAmount}';
      return;
    }

    final nextValue = parsed.clamp(0, 9999);
    if (_isUpdatingQuantity) return;

    if (nextValue == _item.totalAmount) {
      _quantityController.text = '$nextValue';
      return;
    }

    setState(() => _isUpdatingQuantity = true);
    try {
      final updated = await widget.inventoryService.updateTotalAmount(
        item: _item,
        totalAmount: nextValue,
      );
      if (!mounted) return;
      setState(() => _item = updated);
      _quantityController.text = '$nextValue';
    } catch (error) {
      if (!mounted) return;
      _quantityController.text = '${_item.totalAmount}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update quantity: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingQuantity = false);
      }
    }
  }

  @override
  void dispose() {
    _quantityController.removeListener(_handleQuantityDraftChanged);
    _quantityController.dispose();
    _quantityFocusNode.dispose();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete item: $error')));
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
          if (widget.isAdmin) ...[
            IconButton(
              onPressed: _editItem,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: _deleteItem,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
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
                    if (_item.subCategory.isNotEmpty)
                      _InfoPill(text: _item.subCategory),
                    if (_item.isConsumable)
                      const _InfoPill(text: 'Consumable'),
                  ],
                ),
                const SizedBox(height: 20),
                _FieldRow(label: 'Code', value: _item.code),
                _FieldRow(label: 'Name', value: _item.name),
                _FieldRow(label: 'Location', value: _item.location),
                if (!_item.isConsumable) ...[
                  if (widget.isAdmin) ...[
                    _FieldRow(label: 'Total', value: '${_item.totalAmount}'),
                    _FieldRow(
                      label: 'Available',
                      value: '${_item.availableAmount}',
                    ),
                    _FieldRow(label: 'Holding', value: '${_item.holdingAmount}'),
                    _FieldRow(label: 'Rented', value: '${_item.rentedAmount}'),
                  ] else ...[
                    _FieldRow(
                      label: 'Available',
                      value: '${_item.availableAmount}',
                    ),
                  ],
                ] else ...[
                  const _FieldRow(label: 'Status', value: 'Consumable (No quantities tracked)'),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Description',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
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
          if (widget.isAdmin) ...[
            if (!_item.isConsumable)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _cardGrey,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _QuantityStepper(
                      controller: _quantityController,
                      focusNode: _quantityFocusNode,
                      isLoading: _isUpdatingQuantity,
                      onDecrease: () => _adjustQuantity(-1),
                      onIncrease: () => _adjustQuantity(1),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isUpdatingQuantity || !_hasPendingQuantityChange
                          ? null
                          : _submitQuantity,
                      style: FilledButton.styleFrom(
                        backgroundColor: _utmMaroon,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.white),
                  onPressed: _cartQuantity > 1
                      ? () {
                          setState(() => _cartQuantity--);
                        }
                      : null,
                ),
                Text(
                  _cartQuantity.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _isCartQuantityAtLimit
                      ? null
                      : () {
                          setState(() => _cartQuantity++);
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
              onPressed: (!_item.isConsumable && _item.availableAmount <= 0)
                  ? null
                  : () {
                      context.read<CartCubit>().addItem(
                        CartItem(
                          id: widget.item.id,
                          name: widget.item.name,
                          image: widget.item.imageUrl,
                          code: widget.item.code,
                          quantity: _cartQuantity,
                          maxQuantity: _item.isConsumable ? 9999 : _item.availableAmount,
                          isConsumable: _item.isConsumable,
                        ),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            (!_item.isConsumable && _cartQuantity >= _item.availableAmount)
                                ? 'Added to cart up to available stock'
                                : 'Added to cart',
                          ),
                          action: SnackBarAction(
                            label: 'View Cart',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CartScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
              child: const Text(
                'Add to Cart',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onDecrease,
    required this.onIncrease,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
              ),
              onTapOutside: (_) => focusNode.unfocus(),
            ),
          ),
          Container(width: 1, height: double.infinity, color: Colors.white10),
          SizedBox(
            width: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AbsorbPointer(
                  absorbing: isLoading,
                  child: Opacity(
                    opacity: isLoading ? 0.55 : 1,
                    child: Column(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: onIncrease,
                            child: const Center(
                              child: Icon(
                                Icons.keyboard_arrow_up,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Container(height: 1, color: Colors.white10),
                        Expanded(
                          child: InkWell(
                            onTap: onDecrease,
                            child: const Center(
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value});

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
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
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
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.imageUrl, this.size = 96});

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
            ? const Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: _utmMaroon,
              )
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
