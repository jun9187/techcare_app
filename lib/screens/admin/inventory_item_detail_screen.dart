import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/inventory_item.dart';
import '../../services/inventory_service.dart';
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
  late final TextEditingController _quantityController;
  late final FocusNode _quantityFocusNode;
  Timer? _quantityDebounce;
  bool _isProgrammaticQuantityChange = false;
  bool _isUpdatingQuantity = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _quantityController = TextEditingController(text: '${_item.quantity}');
    _quantityFocusNode = FocusNode();
  }

  Future<void> _adjustQuantity(int delta) async {
    final nextValue = (_item.quantity + delta).clamp(0, 9999);
    if (nextValue == _item.quantity) return;

    _setQuantityText('$nextValue');
    await _submitQuantity();
  }

  Future<void> _submitQuantity() async {
    _quantityDebounce?.cancel();
    final parsed = int.tryParse(_quantityController.text.trim());
    if (parsed == null) {
      _setQuantityText('${_item.quantity}');
      return;
    }

    final nextValue = parsed.clamp(0, 9999);
    if (_isUpdatingQuantity) return;

    if (nextValue == _item.quantity) {
      _setQuantityText('$nextValue');
      return;
    }

    setState(() => _isUpdatingQuantity = true);
    try {
      await widget.inventoryService.updateQuantity(
        itemId: _item.id,
        quantity: nextValue,
      );
      if (!mounted) return;
      setState(() => _item = _item.copyWith(quantity: nextValue));
      _setQuantityText('$nextValue');
    } catch (error) {
      if (!mounted) return;
      _setQuantityText('${_item.quantity}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update quantity: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingQuantity = false);
        if (_quantityController.text.trim() != '${_item.quantity}') {
          _scheduleQuantitySubmit();
        }
      }
    }
  }

  void _setQuantityText(String value) {
    _isProgrammaticQuantityChange = true;
    _quantityController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _isProgrammaticQuantityChange = false;
  }

  void _scheduleQuantitySubmit() {
    _quantityDebounce?.cancel();
    _quantityDebounce = Timer(const Duration(milliseconds: 450), () {
      _submitQuantity();
    });
  }

  void _handleQuantityChanged(String value) {
    if (_isProgrammaticQuantityChange) return;
    _scheduleQuantitySubmit();
  }

  @override
  void dispose() {
    _quantityDebounce?.cancel();
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
          IconButton(
            onPressed: _editItem,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _deleteItem,
            icon: const Icon(Icons.delete_outline),
          ),
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
                        'Stock Control',
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
                  onChanged: _handleQuantityChanged,
                  onSubmitted: _submitQuantity,
                  onDecrease: () => _adjustQuantity(-1),
                  onIncrease: () => _adjustQuantity(1),
                ),
              ],
            ),
          ),
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
    required this.onChanged,
    required this.onSubmitted,
    required this.onDecrease,
    required this.onIncrease,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
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
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              ),
              onChanged: onChanged,
              onSubmitted: (_) => onSubmitted(),
              onTapOutside: (_) => focusNode.unfocus(),
              onEditingComplete: onSubmitted,
            ),
          ),
          Container(
            width: 1,
            height: double.infinity,
            color: Colors.white10,
          ),
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
                              child: Icon(Icons.keyboard_arrow_up, color: Colors.white),
                            ),
                          ),
                        ),
                        Container(height: 1, color: Colors.white10),
                        Expanded(
                          child: InkWell(
                            onTap: onDecrease,
                            child: const Center(
                              child: Icon(Icons.keyboard_arrow_down, color: Colors.white),
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
