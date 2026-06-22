import 'package:flutter/material.dart';

import '../../models/inventory_item.dart';
import '../../models/rental_request.dart';
import '../../services/rental_request_service.dart';
import '../rental_request_detail_screen.dart';

const Color _backgroundDark = Color(0xFF0F0F0F);
const Color _cardGrey = Color(0xFF1B1B1B);
const Color _utmMaroon = Color(0xFF800000);

class AdminRequestFilterController extends ChangeNotifier {
  InventoryItem? _item;

  InventoryItem? get item => _item;

  void filterByItem(InventoryItem item) {
    _item = item;
    notifyListeners();
  }
}

class AdminItemRequestsPage extends StatefulWidget {
  const AdminItemRequestsPage({super.key, required this.item});

  final InventoryItem item;

  @override
  State<AdminItemRequestsPage> createState() => _AdminItemRequestsPageState();
}

class _AdminItemRequestsPageState extends State<AdminItemRequestsPage> {
  late final AdminRequestFilterController _filterController;

  @override
  void initState() {
    super.initState();
    _filterController = AdminRequestFilterController()
      ..filterByItem(widget.item);
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _backgroundDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rental Requests'),
            Text(
              widget.item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: AdminRequestsScreen(filterController: _filterController),
    );
  }
}

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key, this.filterController});

  final AdminRequestFilterController? filterController;

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  final RentalRequestService _requestService = RentalRequestService();
  final TextEditingController _searchController = TextEditingController();
  RentalRequestStatus? _selectedStatus;
  String _searchQuery = '';
  bool _showAdvancedFilters = false;
  _StudentFilterOption? _selectedStudent;
  _ItemFilterOption? _selectedItem;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    widget.filterController?.addListener(_applyExternalItemFilter);
    _applyExternalItemFilter();
  }

  @override
  void didUpdateWidget(covariant AdminRequestsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterController == widget.filterController) return;
    oldWidget.filterController?.removeListener(_applyExternalItemFilter);
    widget.filterController?.addListener(_applyExternalItemFilter);
    _applyExternalItemFilter();
  }

  @override
  void dispose() {
    widget.filterController?.removeListener(_applyExternalItemFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyExternalItemFilter() {
    final item = widget.filterController?.item;
    if (item == null) return;

    setState(() {
      _selectedItem = _ItemFilterOption(
        id: item.id,
        name: item.name,
        code: item.code,
      );
      _showAdvancedFilters = true;
    });
  }

  List<RentalRequest> _filteredRequests(List<RentalRequest> requests) {
    final selectedStatus = _selectedStatus;
    final query = _searchQuery.trim().toLowerCase();
    final selectedStudent = _selectedStudent;
    final selectedItem = _selectedItem;
    final selectedDateRange = _selectedDateRange;

    return requests
        .where((request) {
          if (selectedStatus != null && request.status != selectedStatus) {
            return false;
          }

          if (query.isNotEmpty) {
            final haystack = [
              request.requesterName,
              request.matricNumber,
              request.requesterEmail,
              request.referenceId,
              ...request.items.expand((item) => [item.name, item.code]),
            ].join(' ').toLowerCase();
            if (!haystack.contains(query)) return false;
          }

          if (selectedStudent != null &&
              selectedStudent.key !=
                  _StudentFilterOption.fromRequest(request).key) {
            return false;
          }

          if (selectedItem != null &&
              !request.items.any(selectedItem.matchesRequestItem)) {
            return false;
          }

          if (selectedDateRange != null) {
            final submitted = request.submittedAt?.toLocal();
            if (submitted == null) return false;
            final submittedDate = DateTime(
              submitted.year,
              submitted.month,
              submitted.day,
            );
            final start = DateTime(
              selectedDateRange.start.year,
              selectedDateRange.start.month,
              selectedDateRange.start.day,
            );
            final end = DateTime(
              selectedDateRange.end.year,
              selectedDateRange.end.month,
              selectedDateRange.end.day,
            );
            if (submittedDate.isBefore(start) || submittedDate.isAfter(end)) {
              return false;
            }
          }

          return true;
        })
        .toList(growable: false);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange:
          _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _utmMaroon,
              surface: _cardGrey,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _clearAdvancedFilters() {
    setState(() {
      _selectedStudent = null;
      _selectedItem = null;
      _selectedDateRange = null;
    });
  }

  void _openRequest(RentalRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RentalRequestDetailScreen(requestId: request.id, isAdmin: true),
      ),
    );
  }

  List<_StudentFilterOption> _studentOptions(List<RentalRequest> requests) {
    final options = <String, _StudentFilterOption>{};
    for (final request in requests) {
      final option = _StudentFilterOption.fromRequest(request);
      options[option.key] = option;
    }
    final result = options.values.toList(growable: false);
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  List<_ItemFilterOption> _itemOptions(List<RentalRequest> requests) {
    final options = <String, _ItemFilterOption>{};
    for (final request in requests) {
      for (final item in request.items) {
        final option = _ItemFilterOption.fromRequestItem(item);
        options[option.key] = option;
      }
    }
    final result = options.values.toList(growable: false);
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  Future<void> _selectStudent(List<_StudentFilterOption> options) async {
    final selected = await _showSearchSelection<_StudentFilterOption>(
      context: context,
      title: 'Select Student',
      searchHint: 'Search name, matric number, or email',
      options: options,
      matches: (option, query) => option.matches(query),
      titleText: (option) => option.name,
      subtitleText: (option) => option.matricNumber.isEmpty
          ? 'No matric number'
          : option.matricNumber,
    );
    if (selected != null && mounted) {
      setState(() => _selectedStudent = selected);
    }
  }

  Future<void> _selectItem(List<_ItemFilterOption> options) async {
    final selected = await _showSearchSelection<_ItemFilterOption>(
      context: context,
      title: 'Select Item',
      searchHint: 'Search item name or code',
      options: options,
      matches: (option, query) => option.matches(query),
      titleText: (option) => option.name,
      subtitleText: (option) =>
          option.code.isEmpty ? 'No item code' : option.code,
    );
    if (selected != null && mounted) {
      setState(() => _selectedItem = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _backgroundDark,
      child: StreamBuilder<List<RentalRequest>>(
        stream: _requestService.watchRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.error_outline_rounded,
              message: 'Unable to load requests.',
              detail: '${snapshot.error}',
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!;
          final filteredRequests = _filteredRequests(requests);
          final studentOptions = _studentOptions(requests);
          final itemOptions = _itemOptions(requests);
          final hasAdvancedFilters =
              _selectedStudent != null ||
              _selectedItem != null ||
              _selectedDateRange != null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              _SearchField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _selectedStatus == null,
                      onTap: () => setState(() => _selectedStatus = null),
                    ),
                    _FilterChip(
                      label: 'Pending',
                      selected: _selectedStatus == RentalRequestStatus.pending,
                      onTap: () => setState(
                        () => _selectedStatus = RentalRequestStatus.pending,
                      ),
                    ),
                    _FilterChip(
                      label: 'Approved',
                      selected: _selectedStatus == RentalRequestStatus.approved,
                      onTap: () => setState(
                        () => _selectedStatus = RentalRequestStatus.approved,
                      ),
                    ),
                    _FilterChip(
                      label: 'Returned',
                      selected: _selectedStatus == RentalRequestStatus.returned,
                      onTap: () => setState(
                        () => _selectedStatus = RentalRequestStatus.returned,
                      ),
                    ),
                    _FilterChip(
                      label: 'Rejected',
                      selected: _selectedStatus == RentalRequestStatus.rejected,
                      onTap: () => setState(
                        () => _selectedStatus = RentalRequestStatus.rejected,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _AdvancedFilterToggle(
                expanded: _showAdvancedFilters,
                active: hasAdvancedFilters,
                onTap: () => setState(
                  () => _showAdvancedFilters = !_showAdvancedFilters,
                ),
              ),
              if (_showAdvancedFilters) ...[
                const SizedBox(height: 12),
                _AdvancedFilterPanel(
                  selectedStudent: _selectedStudent,
                  selectedItem: _selectedItem,
                  selectedDateRange: _selectedDateRange,
                  onSelectStudent: () => _selectStudent(studentOptions),
                  onClearStudent: () => setState(() => _selectedStudent = null),
                  onSelectItem: () => _selectItem(itemOptions),
                  onClearItem: () => setState(() => _selectedItem = null),
                  onSelectDateRange: _pickDateRange,
                  onClearDateRange: () =>
                      setState(() => _selectedDateRange = null),
                  onClearAll: hasAdvancedFilters ? _clearAdvancedFilters : null,
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Rental Requests',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${filteredRequests.length} shown',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (filteredRequests.isEmpty)
                const _MessageCard(
                  icon: Icons.assignment_outlined,
                  message: 'No requests',
                )
              else
                ...filteredRequests.map(
                  (request) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RequestCard(
                      request: request,
                      onTap: () => _openRequest(request),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by name, matric no. or reference',
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: _cardGrey,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _utmMaroon, width: 1.4),
        ),
      ),
    );
  }
}

class _AdvancedFilterToggle extends StatelessWidget {
  const _AdvancedFilterToggle({
    required this.expanded,
    required this.active,
    required this.onTap,
  });

  final bool expanded;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(expanded ? Icons.expand_less_rounded : Icons.tune_rounded),
        label: Text(active ? 'Advanced filters active' : 'Advanced filters'),
        style: TextButton.styleFrom(
          foregroundColor: active ? Colors.white : Colors.white70,
          backgroundColor: active
              ? _utmMaroon.withValues(alpha: 0.28)
              : _cardGrey,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _AdvancedFilterPanel extends StatelessWidget {
  const _AdvancedFilterPanel({
    required this.selectedStudent,
    required this.selectedItem,
    required this.selectedDateRange,
    required this.onSelectStudent,
    required this.onClearStudent,
    required this.onSelectItem,
    required this.onClearItem,
    required this.onSelectDateRange,
    required this.onClearDateRange,
    required this.onClearAll,
  });

  final _StudentFilterOption? selectedStudent;
  final _ItemFilterOption? selectedItem;
  final DateTimeRange? selectedDateRange;
  final VoidCallback onSelectStudent;
  final VoidCallback onClearStudent;
  final VoidCallback onSelectItem;
  final VoidCallback onClearItem;
  final VoidCallback onSelectDateRange;
  final VoidCallback onClearDateRange;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Advanced Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onClearAll != null)
                TextButton(
                  onPressed: onClearAll,
                  child: const Text('Clear all'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _SelectionField(
            label: 'Student',
            value: selectedStudent?.displayLabel,
            icon: Icons.person_search_rounded,
            onTap: onSelectStudent,
            onClear: selectedStudent == null ? null : onClearStudent,
          ),
          const SizedBox(height: 12),
          _SelectionField(
            label: 'Item',
            value: selectedItem?.name,
            icon: Icons.inventory_2_outlined,
            onTap: onSelectItem,
            onClear: selectedItem == null ? null : onClearItem,
          ),
          const SizedBox(height: 12),
          _SelectionField(
            label: 'Date Range',
            value: selectedDateRange == null
                ? null
                : _formatDateRange(selectedDateRange!),
            icon: Icons.date_range_rounded,
            onTap: onSelectDateRange,
            onClear: selectedDateRange == null ? null : onClearDateRange,
          ),
          const SizedBox(height: 10),
          const Text(
            'Search and status filters above are also applied.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value == null
                ? Colors.white.withValues(alpha: 0.08)
                : _utmMaroon,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value ?? 'Any $label',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: value == null ? Colors.white54 : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                  size: 19,
                ),
              )
            else
              const Icon(Icons.arrow_drop_down_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final RentalRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstItem = request.items.isEmpty
        ? 'No items'
        : request.items.first.name;
    final extraCount = request.items.length - 1;

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
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _utmMaroon.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.assignment_outlined, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.requesterName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  if (request.matricNumber.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      request.matricNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    extraCount > 0 ? '$firstItem +$extraCount' : firstItem,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${request.referenceId} - ${formatRentalDate(request.submittedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusChip(status: request.status, label: request.statusLabel),
                const SizedBox(height: 8),
                Text(
                  '${request.totalQuantity} unit(s)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => onTap(),
        selectedColor: _utmMaroon,
        backgroundColor: _cardGrey,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.label});

  final RentalRequestStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      RentalRequestStatus.approved => const Color(0xFF1E7B34),
      RentalRequestStatus.rejected => const Color(0xFFB42318),
      RentalRequestStatus.returned => const Color(0xFF2563EB),
      RentalRequestStatus.pending => const Color(0xFFFFD700),
    };
    final textColor = status == RentalRequestStatus.pending
        ? Colors.black
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StudentFilterOption {
  const _StudentFilterOption({
    required this.uid,
    required this.name,
    required this.matricNumber,
    required this.email,
  });

  factory _StudentFilterOption.fromRequest(RentalRequest request) {
    return _StudentFilterOption(
      uid: request.requesterUid,
      name: request.requesterName,
      matricNumber: request.matricNumber,
      email: request.requesterEmail,
    );
  }

  final String uid;
  final String name;
  final String matricNumber;
  final String email;

  String get key {
    if (uid.isNotEmpty) return 'uid:$uid';
    return 'identity:${name.toLowerCase()}|'
        '${matricNumber.toLowerCase()}|${email.toLowerCase()}';
  }

  String get displayLabel =>
      matricNumber.isEmpty ? name : '$name • $matricNumber';

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    return [
      name,
      matricNumber,
      email,
    ].join(' ').toLowerCase().contains(normalized);
  }
}

class _ItemFilterOption {
  const _ItemFilterOption({
    required this.id,
    required this.name,
    required this.code,
  });

  factory _ItemFilterOption.fromRequestItem(RentalRequestItem item) {
    return _ItemFilterOption(id: item.itemId, name: item.name, code: item.code);
  }

  final String id;
  final String name;
  final String code;

  String get key {
    if (id.isNotEmpty) return 'id:$id';
    return 'identity:${name.toLowerCase()}|${code.toLowerCase()}';
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    return '$name $code'.toLowerCase().contains(normalized);
  }

  bool matchesRequestItem(RentalRequestItem item) {
    if (id.isNotEmpty && item.itemId.isNotEmpty) {
      return id == item.itemId;
    }
    if (code.isNotEmpty && item.code.isNotEmpty) {
      return code.toLowerCase() == item.code.toLowerCase();
    }
    return name.toLowerCase() == item.name.toLowerCase();
  }
}

Future<T?> _showSearchSelection<T>({
  required BuildContext context,
  required String title,
  required String searchHint,
  required List<T> options,
  required bool Function(T option, String query) matches,
  required String Function(T option) titleText,
  required String Function(T option) subtitleText,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _cardGrey,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _SearchSelectionSheet<T>(
      title: title,
      searchHint: searchHint,
      options: options,
      matches: matches,
      titleText: titleText,
      subtitleText: subtitleText,
    ),
  );
}

class _SearchSelectionSheet<T> extends StatefulWidget {
  const _SearchSelectionSheet({
    required this.title,
    required this.searchHint,
    required this.options,
    required this.matches,
    required this.titleText,
    required this.subtitleText,
  });

  final String title;
  final String searchHint;
  final List<T> options;
  final bool Function(T option, String query) matches;
  final String Function(T option) titleText;
  final String Function(T option) subtitleText;

  @override
  State<_SearchSelectionSheet<T>> createState() =>
      _SearchSelectionSheetState<T>();
}

class _SearchSelectionSheetState<T> extends State<_SearchSelectionSheet<T>> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.options
        : widget.options
              .where((option) => widget.matches(option, _query))
              .toList(growable: false);

    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching options.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          Divider(color: Colors.white.withValues(alpha: 0.07)),
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            widget.titleText(option),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            widget.subtitleText(option),
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
                          ),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            Navigator.pop(context, option);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateRange(DateTimeRange range) {
  String format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  return '${format(range.start)} – ${format(range.end)}';
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 42),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message, this.detail});

  final IconData icon;
  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
