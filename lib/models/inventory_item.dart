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
    required this.totalAmount,
    required this.availableAmount,
    required this.holdingAmount,
    required this.rentedAmount,
    required this.imageUrl,
    required this.timestamp,
    this.amountType = 'unit',
  });

  final String id;
  final String code;
  final String name;
  final String category;
  final String subCategory;
  final String description;
  final String location;
  final int totalAmount;
  final int availableAmount;
  final int holdingAmount;
  final int rentedAmount;
  final String imageUrl;
  final DateTime? timestamp;
  final String amountType;

  int get quantity => availableAmount;

  bool get isConsumable => amountType == 'consumable';
  bool get isLowStock => !isConsumable && availableAmount <= 3;
  bool get isOutOfStock => !isConsumable && availableAmount <= 0;

  String get statusLabel {
    if (isConsumable) return 'Consumable';
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'Available';
  }

  factory InventoryItem.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return InventoryItem.fromData(
      id: doc.id,
      data: doc.data() ?? <String, dynamic>{},
    );
  }

  factory InventoryItem.fromData({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final timestampValue = data['timestamp'];
    final legacyQuantity = _readInt(data, ['Quantity', 'quantity']);
    final totalAmount =
        _readNullableInt(data, ['totalAmount']) ?? legacyQuantity;
    final holdingAmount = _readNullableInt(data, ['holdingAmount']) ?? 0;
    final rentedAmount = _readNullableInt(data, ['rentedAmount']) ?? 0;
    final computedAvailable = totalAmount - holdingAmount - rentedAmount;
    final availableAmount =
        _readNullableInt(data, ['availableAmount']) ??
        computedAvailable.clamp(0, totalAmount).toInt();

    var amountType = _readString(data, ['amountType', 'type']) ?? 'unit';
    if (amountType == 'rental') {
      amountType = 'unit';
    }

    return InventoryItem(
      id: id,
      code: _readString(data, ['code']) ?? id,
      name: _readString(data, ['Name', 'name']) ?? 'Unnamed Item',
      category: _readString(data, ['Category', 'category']) ?? 'Uncategorized',
      subCategory:
          _readString(data, ['Sub-category', 'subCategory', 'SubCategory']) ??
          '',
      description:
          _readString(data, ['Description', 'description']) ??
          'No description provided.',
      location: _readString(data, ['Location', 'location']) ?? 'Unknown',
      totalAmount: totalAmount,
      availableAmount: availableAmount,
      holdingAmount: holdingAmount,
      rentedAmount: rentedAmount,
      imageUrl: _readString(data, ['image', 'imageUrl']) ?? '',
      timestamp: timestampValue is Timestamp ? timestampValue.toDate() : null,
      amountType: amountType,
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'code': code,
      'Name': name,
      'Category': category,
      'Sub-category': subCategory,
      'Description': description,
      'Location': location,
      'image': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'amountType': amountType,
    };

    if (!isConsumable) {
      data.addAll({
        'totalAmount': totalAmount,
        'availableAmount': availableAmount,
        'holdingAmount': holdingAmount,
        'rentedAmount': rentedAmount,
        'Quantity': totalAmount,
      });
    }

    return data;
  }

  InventoryItem copyWith({
    String? code,
    String? name,
    String? category,
    String? subCategory,
    String? description,
    String? location,
    int? totalAmount,
    int? availableAmount,
    int? holdingAmount,
    int? rentedAmount,
    String? imageUrl,
    DateTime? timestamp,
    String? amountType,
  }) {
    return InventoryItem(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      description: description ?? this.description,
      location: location ?? this.location,
      totalAmount: totalAmount ?? this.totalAmount,
      availableAmount: availableAmount ?? this.availableAmount,
      holdingAmount: holdingAmount ?? this.holdingAmount,
      rentedAmount: rentedAmount ?? this.rentedAmount,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      amountType: amountType ?? this.amountType,
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
    return _readNullableInt(data, keys) ?? 0;
  }

  static int? _readNullableInt(Map<String, dynamic> data, List<String> keys) {
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
    return null;
  }
}
