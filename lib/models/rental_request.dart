import 'package:cloud_firestore/cloud_firestore.dart';

enum RentalRequestStatus { pending, approved, rejected, returned }

class RentalRequestItem {
  const RentalRequestItem({
    required this.itemId,
    required this.code,
    required this.name,
    required this.imageUrl,
    required this.quantity,
  });

  final String itemId;
  final String code;
  final String name;
  final String imageUrl;
  final int quantity;

  factory RentalRequestItem.fromMap(Map<String, dynamic> data) {
    return RentalRequestItem(
      itemId: _readString(data, ['itemId', 'id']) ?? '',
      code: _readString(data, ['code']) ?? '',
      name: _readString(data, ['name']) ?? 'Unnamed Item',
      imageUrl: _readString(data, ['imageUrl', 'image']) ?? '',
      quantity: _readInt(data, ['quantity']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'code': code,
      'name': name,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }
}

class RentalRequest {
  const RentalRequest({
    required this.id,
    required this.referenceId,
    required this.requesterUid,
    required this.requesterName,
    required this.requesterEmail,
    required this.matricNumber,
    required this.status,
    required this.submittedAt,
    required this.decidedAt,
    required this.decidedByUid,
    required this.returnedAt,
    required this.returnedByUid,
    required this.items,
  });

  final String id;
  final String referenceId;
  final String requesterUid;
  final String requesterName;
  final String requesterEmail;
  final String matricNumber;
  final RentalRequestStatus status;
  final DateTime? submittedAt;
  final DateTime? decidedAt;
  final String? decidedByUid;
  final DateTime? returnedAt;
  final String? returnedByUid;
  final List<RentalRequestItem> items;

  int get totalQuantity =>
      items.fold<int>(0, (total, item) => total + item.quantity);

  bool get isPending => status == RentalRequestStatus.pending;

  String get statusValue => status.name;

  String get statusLabel {
    switch (status) {
      case RentalRequestStatus.approved:
        return 'Approved';
      case RentalRequestStatus.rejected:
        return 'Rejected';
      case RentalRequestStatus.returned:
        return 'Returned';
      case RentalRequestStatus.pending:
        return 'Pending';
    }
  }

  factory RentalRequest.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final itemsValue = data['items'];
    final items = <RentalRequestItem>[];

    if (itemsValue is Iterable) {
      for (final value in itemsValue) {
        if (value is Map) {
          items.add(
            RentalRequestItem.fromMap(Map<String, dynamic>.from(value)),
          );
        }
      }
    }

    return RentalRequest(
      id: doc.id,
      referenceId: _readString(data, ['referenceId', 'Reference_ID']) ?? doc.id,
      requesterUid: _readString(data, ['requesterUid', 'uid']) ?? '',
      requesterName:
          _readString(data, ['requesterName', 'Name', 'name']) ?? 'Student',
      requesterEmail:
          _readString(data, ['requesterEmail', 'Email', 'email']) ?? '',
      matricNumber: _readString(data, ['matricNumber']) ?? '',
      status: rentalRequestStatusFromString(
        _readString(data, ['status', 'Status']),
      ),
      submittedAt: _readDateTime(data['submittedAt'] ?? data['Date_Submitted']),
      decidedAt: _readDateTime(data['decidedAt']),
      decidedByUid: _readString(data, ['decidedByUid']),
      returnedAt: _readDateTime(data['returnedAt']),
      returnedByUid: _readString(data, ['returnedByUid']),
      items: items,
    );
  }
}

RentalRequestStatus rentalRequestStatusFromString(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'approved':
    case 'a':
      return RentalRequestStatus.approved;
    case 'rejected':
    case 'r':
      return RentalRequestStatus.rejected;
    case 'returned':
      return RentalRequestStatus.returned;
    case 'pending':
    case 'p':
    default:
      return RentalRequestStatus.pending;
  }
}

String formatRentalDate(DateTime? value) {
  if (value == null) return 'Just now';

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month/${local.year} $hour:$minute';
}

String? _readString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

int _readInt(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      final parsedDouble = double.tryParse(value);
      if (parsedDouble != null) return parsedDouble.round();
    }
  }
  return 0;
}

DateTime? _readDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
