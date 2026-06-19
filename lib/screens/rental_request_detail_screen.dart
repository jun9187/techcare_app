import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../models/rental_request.dart';
import '../services/rental_request_service.dart';

const Color _backgroundDark = Color(0xFF0F0F0F);
const Color _cardGrey = Color(0xFF1B1B1B);
const Color _utmMaroon = Color(0xFF800000);

class RentalRequestDetailScreen extends StatefulWidget {
  const RentalRequestDetailScreen({
    super.key,
    required this.requestId,
    this.isAdmin = false,
  });

  final String requestId;
  final bool isAdmin;

  @override
  State<RentalRequestDetailScreen> createState() =>
      _RentalRequestDetailScreenState();
}

class _RentalRequestDetailScreenState extends State<RentalRequestDetailScreen> {
  final RentalRequestService _requestService = RentalRequestService();
  bool _isDeciding = false;

  Future<void> _decideRequest({
    required RentalRequest request,
    required bool approve,
  }) async {
    final state = context.read<AuthBloc>().state;
    if (state is! Authenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login again.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve request?' : 'Reject request?'),
        content: Text(
          approve
              ? 'Approve ${request.referenceId} and mark the items as rented?'
              : 'Reject ${request.referenceId} and release the held stock?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _isDeciding = true);
    try {
      if (approve) {
        await _requestService.approveRequest(
          requestId: request.id,
          adminUid: state.uid,
        );
      } else {
        await _requestService.rejectRequest(
          requestId: request.id,
          adminUid: state.uid,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Request approved.' : 'Request rejected.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() => _isDeciding = false);
      }
    }
  }

  Future<void> _returnRequest(RentalRequest request) async {
    final state = context.read<AuthBloc>().state;
    if (state is! Authenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login again.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm return?'),
        content: Text('Mark ${request.referenceId} as returned?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Return'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeciding = true);
    try {
      await _requestService.returnRequest(
        requestId: request.id,
        adminUid: state.uid,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Items returned.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() => _isDeciding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _backgroundDark,
        title: const Text('Request Details'),
      ),
      body: StreamBuilder<RentalRequest?>(
        stream: _requestService.watchRequest(widget.requestId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.error_outline_rounded,
              message: 'Unable to load request.',
              detail: '${snapshot.error}',
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final request = snapshot.data;
          if (request == null) {
            return const _MessageState(
              icon: Icons.assignment_late_outlined,
              message: 'Request not found.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _RequestHeader(request: request),
              const SizedBox(height: 12),
              _InfoCard(request: request),
              const SizedBox(height: 12),
              _ItemsCard(items: request.items),
              if (widget.isAdmin && request.isPending) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isDeciding
                            ? null
                            : () => _decideRequest(
                                request: request,
                                approve: false,
                              ),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isDeciding
                            ? null
                            : () => _decideRequest(
                                request: request,
                                approve: true,
                              ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _utmMaroon,
                          foregroundColor: Colors.white,
                        ),
                        icon: _isDeciding
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
              if (widget.isAdmin &&
                  request.status == RentalRequestStatus.approved) ...[
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _isDeciding
                        ? null
                        : () => _returnRequest(request),
                    style: FilledButton.styleFrom(
                      backgroundColor: _utmMaroon,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isDeciding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.assignment_return_rounded),
                    label: const Text('Return Items'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RequestHeader extends StatelessWidget {
  const _RequestHeader({required this.request});

  final RentalRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.referenceId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatRentalDate(request.submittedAt),
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusChip(status: request.status, label: request.statusLabel),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.request});

  final RentalRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _FieldRow(label: 'Student', value: request.requesterName),
          _FieldRow(label: 'Email', value: request.requesterEmail),
          if (request.matricNumber.isNotEmpty)
            _FieldRow(label: 'Matric', value: request.matricNumber),
          _FieldRow(label: 'Total', value: '${request.totalQuantity} unit(s)'),
          if (request.decidedAt != null)
            _FieldRow(
              label: 'Decided',
              value: formatRentalDate(request.decidedAt),
            ),
          if (request.returnedAt != null)
            _FieldRow(
              label: 'Returned',
              value: formatRentalDate(request.returnedAt),
            ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.items});

  final List<RentalRequestItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 4, 10),
            child: Text(
              'Items',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(4),
              child: Text('No items', style: TextStyle(color: Colors.white70)),
            )
          else
            ...items.map((item) => _RequestItemTile(item: item)),
        ],
      ),
    );
  }
}

class _RequestItemTile extends StatelessWidget {
  const _RequestItemTile({required this.item});

  final RentalRequestItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 54,
              height: 54,
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'x${item.quantity}',
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
            width: 76,
            child: Text(label, style: const TextStyle(color: Colors.white60)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
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
