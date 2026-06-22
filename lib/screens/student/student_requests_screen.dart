import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/rental_request.dart';
import '../../services/rental_request_service.dart';
import '../rental_request_detail_screen.dart';

const Color _backgroundDark = Color(0xFF0F0F0F);
const Color _cardGrey = Color(0xFF1B1B1B);
const Color _utmMaroon = Color(0xFF800000);

class StudentRequestsScreen extends StatelessWidget {
  const StudentRequestsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;

    final content = state is Authenticated
        ? _StudentRequestsContent(uid: state.uid)
        : const _MessageState(
            icon: Icons.lock_outline_rounded,
            message: 'Please login again.',
          );

    if (embedded) {
      return ColoredBox(color: _backgroundDark, child: content);
    }

    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _backgroundDark,
        title: const Text('My Requests'),
      ),
      body: content,
    );
  }
}

class _StudentRequestsContent extends StatelessWidget {
  _StudentRequestsContent({required this.uid});

  final String uid;
  final RentalRequestService _requestService = RentalRequestService();

  void _openRequest(BuildContext context, RentalRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RentalRequestDetailScreen(requestId: request.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RentalRequest>>(
      stream: _requestService.watchStudentRequests(uid),
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
        if (requests.isEmpty) {
          return const _MessageState(
            icon: Icons.assignment_outlined,
            message: 'No requests yet.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Request Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${requests.length} total',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...requests.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RequestCard(
                  request: request,
                  onTap: () => _openRequest(context, request),
                ),
              ),
            ),
          ],
        );
      },
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
                    request.referenceId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    extraCount > 0 ? '$firstItem +$extraCount' : firstItem,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formatRentalDate(request.submittedAt),
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
