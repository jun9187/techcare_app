import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.description,
    required this.location,
    required this.quantity,
    required this.imageUrl,
    required this.timestamp,
  });

  final String id;
  final String code;
  final String name;
  final String category;
  final String subCategory;
  final String description;
  final String location;
  final int quantity;
  final String imageUrl;
  final DateTime? timestamp;

  bool get isLowStock => quantity <= 3;
  bool get isOutOfStock => quantity <= 0;

  String get statusLabel {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'Available';
  }

  factory InventoryItem.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final timestampValue = data['timestamp'];

    return InventoryItem(
      id: doc.id,
      code: _readString(data, ['code']) ?? doc.id,
      name: _readString(data, ['Name', 'name']) ?? 'Unnamed Item',
      category: _readString(data, ['Category', 'category']) ?? 'Uncategorized',
      subCategory: _readString(data, ['Sub-category', 'subCategory', 'SubCategory']) ?? '',
      description:
          _readString(data, ['Description', 'description']) ?? 'No description provided.',
      location: _readString(data, ['Location', 'location']) ?? 'Unknown',
      quantity: _readInt(data, ['Quantity', 'quantity']),
      imageUrl: _readString(data, ['image', 'imageUrl']) ?? '',
      timestamp: timestampValue is Timestamp ? timestampValue.toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'Name': name,
      'Category': category,
      'Sub-category': subCategory,
      'Description': description,
      'Location': location,
      'Quantity': quantity,
      'image': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  InventoryItem copyWith({
    String? code,
    String? name,
    String? category,
    String? subCategory,
    String? description,
    String? location,
    int? quantity,
    String? imageUrl,
    DateTime? timestamp,
  }) {
    return InventoryItem(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      description: description ?? this.description,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static int _readInt(Map<String, dynamic> data, List<String> keys) {
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
}
