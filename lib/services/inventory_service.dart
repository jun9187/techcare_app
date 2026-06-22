import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../models/inventory_item.dart';

const String _cloudinaryCloudName = String.fromEnvironment(
  'CLOUDINARY_CLOUD_NAME',
);
const String _cloudinaryUploadPreset = String.fromEnvironment(
  'CLOUDINARY_UPLOAD_PRESET',
);

class InventoryService {
  InventoryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _inventoryRef =>
      _firestore.collection('inventory');

  Stream<List<InventoryItem>> watchInventory() {
    return _inventoryRef
        .orderBy('Name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(InventoryItem.fromDocument)
              .toList(growable: false),
        );
  }

  Future<void> addItem(InventoryItem item) async {
    _validateStock(item);
    await _inventoryRef.add(item.toFirestore());
  }

  Future<void> updateItem(InventoryItem item) async {
    _validateStock(item);
    await _inventoryRef
        .doc(item.id)
        .set(item.toFirestore(), SetOptions(merge: true));
  }

  Future<InventoryItem> updateTotalAmount({
    required InventoryItem item,
    required int totalAmount,
  }) async {
    return _firestore.runTransaction((transaction) async {
      final itemRef = _inventoryRef.doc(item.id);
      final itemDoc = await transaction.get(itemRef);
      final current = itemDoc.exists
          ? InventoryItem.fromDocument(itemDoc)
          : item;
      final activeAmount = current.holdingAmount + current.rentedAmount;

      if (totalAmount < activeAmount) {
        throw Exception('Total cannot be less than holding and rented amount.');
      }

      final updated = current.copyWith(
        totalAmount: totalAmount,
        availableAmount: totalAmount - activeAmount,
      );

      transaction.set(itemRef, updated.toFirestore(), SetOptions(merge: true));
      return updated;
    });
  }

  Future<void> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    await _inventoryRef.doc(itemId).set({
      'totalAmount': quantity,
      'availableAmount': quantity,
      'holdingAmount': 0,
      'rentedAmount': 0,
      'Quantity': quantity,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteItem(String itemId) async {
    await _inventoryRef.doc(itemId).delete();
  }

  Future<String> uploadItemImage({
    required XFile imageFile,
    required String itemCode,
  }) async {
    if (_cloudinaryCloudName.isEmpty || _cloudinaryUploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary is not configured. Run the app with '
        '--dart-define=CLOUDINARY_CLOUD_NAME=... '
        '--dart-define=CLOUDINARY_UPLOAD_PRESET=...',
      );
    }

    final extension = imageFile.name.contains('.')
        ? imageFile.name.split('.').last.toLowerCase()
        : 'jpg';
    final safeCode = (itemCode.trim().isEmpty ? 'item' : itemCode.trim())
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final publicId = '${safeCode}_${DateTime.now().millisecondsSinceEpoch}';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..fields['folder'] = 'techcare/inventory'
      ..fields['public_id'] = publicId
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          await imageFile.readAsBytes(),
          filename: imageFile.name.isNotEmpty
              ? imageFile.name
              : '$publicId.$extension',
        ),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final payload = jsonDecode(responseBody) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload['error'];
      final message = error is Map<String, dynamic>
          ? (error['message'] ?? error.toString()).toString()
          : 'Unknown Cloudinary upload error.';
      throw Exception(message);
    }

    final secureUrl = payload['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception(
        'Cloudinary upload succeeded but no image URL was returned.',
      );
    }

    return secureUrl;
  }

  void _validateStock(InventoryItem item) {
    final activeAmount = item.holdingAmount + item.rentedAmount;
    if (item.totalAmount < activeAmount) {
      throw Exception('Total cannot be less than holding and rented amount.');
    }

    if (item.availableAmount != item.totalAmount - activeAmount) {
      throw Exception('Available amount does not match the stock counters.');
    }
  }
}
