import 'package:flutter/material.dart';

import '../../models/inventory_item.dart';
import '../../services/inventory_service.dart';
import 'inventory_item_detail_screen.dart';
import 'inventory_item_form_screen.dart';

const Color _backgroundDark = Color(0xFF0F0F0F);
const Color _cardGrey = Color(0xFF1B1B1B);
const Color _utmMaroon = Color(0xFF800000);
const Color _gold = Color(0xFFFFD700);

class AdminInventoryDashboardScreen extends StatefulWidget {
  const AdminInventoryDashboardScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminInventoryDashboardScreen> createState() =>
      _AdminInventoryDashboardScreenState();
}

class _AdminInventoryDashboardScreenState
    extends State<AdminInventoryDashboardScreen> {
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InventoryItem> _applyFilters(List<InventoryItem> items) {
    final query = _searchController.text.trim().toLowerCase();

    return items
        .where((item) {
          final matchesCategory =
              _selectedCategory == 'All' ||
              item.category.toLowerCase() == _selectedCategory.toLowerCase() ||
              item.subCategory.toLowerCase() == _selectedCategory.toLowerCase();
          final matchesQuery =
              query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.code.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query) ||
              item.subCategory.toLowerCase().contains(query) ||
              item.location.toLowerCase().contains(query);

          return matchesCategory && matchesQuery;
        })
        .toList(growable: false);
  }

  Future<void> _openAddItem() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            InventoryItemFormScreen(inventoryService: _inventoryService),
      ),
    );
  }

  Future<void> _openItemDetail(InventoryItem item) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryItemDetailScreen(
          item: item,
          inventoryService: _inventoryService,
          isAdmin: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<List<InventoryItem>>(
      stream: _inventoryService.watchInventory(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _InventoryErrorState(error: '${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;
        final filteredItems = _applyFilters(items);
        final categories = <String>{
          'All',
          ...items
              .map((item) => item.category)
              .where((value) => value.isNotEmpty),
        }.toList(growable: false);
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  widget.embedded ? 16 : 12,
                  20,
                  100,
                ),
                children: [
                  if (!widget.embedded) const _WelcomePanel(),
                  const SizedBox(height: 18),
                  _SearchBar(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final selected = category == _selectedCategory;
                        return ChoiceChip(
                          selected: selected,
                          label: Text(category),
                          onSelected: (_) =>
                              setState(() => _selectedCategory = category),
                          selectedColor: _utmMaroon,
                          backgroundColor: _cardGrey,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Inventory List',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${filteredItems.length} shown',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (filteredItems.isEmpty)
                    const _EmptyInventoryState()
                  else
                    ...filteredItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _InventoryListCard(
                          item: item,
                          onTap: () => _openItemDetail(item),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: _openAddItem,
                backgroundColor: _utmMaroon,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
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
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _backgroundDark,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TechCare'),
            SizedBox(height: 2),
            Text(
              'Admin Inventory',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: content,
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A0D0D), Color(0xFF8B1E1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Manage stock',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Search by item name, code, category, or location',
          prefixIcon: Icon(Icons.search_rounded),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _InventoryListCard extends StatelessWidget {
  const _InventoryListCard({required this.item, required this.onTap});

  final InventoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isConsumable
        ? const Color(0xFF2563EB)
        : item.isOutOfStock
        ? const Color(0xFFB42318)
        : item.isLowStock
        ? _gold
        : const Color(0xFF1E7B34);
    final statusTextColor = (item.isLowStock && !item.isOutOfStock && !item.isConsumable)
        ? Colors.black
        : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardGrey,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 78,
                width: 78,
                color: Colors.white,
                child: item.imageUrl.isEmpty
                    ? const Icon(Icons.inventory_2_outlined, color: _utmMaroon)
                    : Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.inventory_2_outlined,
                          color: _utmMaroon,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
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
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.category}${item.subCategory.isNotEmpty ? ' • ${item.subCategory}' : ''}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Code: ${item.code}   Location: ${item.location}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 12,
                    ),
                  ),
                  if (!item.isConsumable) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _StockMiniLabel(label: 'Total', value: item.totalAmount),
                        _StockMiniLabel(
                          label: 'Available',
                          value: item.availableAmount,
                        ),
                        _StockMiniLabel(
                          label: 'Holding',
                          value: item.holdingAmount,
                        ),
                        _StockMiniLabel(
                          label: 'Rented',
                          value: item.rentedAmount,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.statusLabel,
                    style: TextStyle(
                      color: statusTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StockMiniLabel extends StatelessWidget {
  const _StockMiniLabel({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.white54),
          SizedBox(height: 12),
          Text(
            'No inventory items match the current filters.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Try another search or add a new item.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _InventoryErrorState extends StatelessWidget {
  const _InventoryErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load inventory right now.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
