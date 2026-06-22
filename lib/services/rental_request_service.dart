import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_item.dart';
import '../models/rental_request.dart';

class RentalRequestService {
  RentalRequestService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _requestsRef =>
      _firestore.collection('rental_requests');

  CollectionReference<Map<String, dynamic>> get _inventoryRef =>
      _firestore.collection('inventory');

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  Stream<List<RentalRequest>> watchRequests() {
    return _requestsRef.snapshots().map(_mapSortedRequests);
  }

  Stream<List<RentalRequest>> watchStudentRequests(String uid) {
    return _requestsRef
        .where('requesterUid', isEqualTo: uid)
        .snapshots()
        .map(_mapSortedRequests);
  }

  Stream<RentalRequest?> watchRequest(String requestId) {
    return _requestsRef.doc(requestId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RentalRequest.fromDocument(doc);
    });
  }

  Future<String> submitRequest({
    required String requesterUid,
    required List<CartItem> cartItems,
  }) async {
    if (cartItems.isEmpty) {
      throw Exception('Cart is empty.');
    }

    final userDoc = await _usersRef.doc(requesterUid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    final currentUser = _auth.currentUser;
    final referenceId = 'REQ-${DateTime.now().millisecondsSinceEpoch}';
    final requestItems = cartItems
        .map(
          (item) => RentalRequestItem(
            itemId: item.id,
            code: item.code,
            name: item.name,
            imageUrl: item.image ?? '',
            quantity: item.quantity,
          ),
        )
        .toList(growable: false);
    final requestRef = _requestsRef.doc();

    await _firestore.runTransaction((transaction) async {
      final stockUpdates = <_StockUpdate>[];

      for (final item in requestItems) {
        final itemRef = _inventoryRef.doc(item.itemId);
        final itemDoc = await transaction.get(itemRef);

        if (!itemDoc.exists) {
          throw Exception('${item.name} is no longer in inventory.');
        }

        final itemData = itemDoc.data() ?? <String, dynamic>{};
        final isConsumable = _readString(itemData, ['type']) == 'consumable';
        if (isConsumable) {
          continue;
        }

        final stock = _readStock(itemData);
        if (stock.availableAmount < item.quantity) {
          throw Exception('Not enough available stock for ${item.name}.');
        }

        stockUpdates.add(
          _StockUpdate(
            ref: itemRef,
            stock: stock.copyWith(
              availableAmount: stock.availableAmount - item.quantity,
              holdingAmount: stock.holdingAmount + item.quantity,
            ),
          ),
        );
      }

      for (final update in stockUpdates) {
        transaction.update(update.ref, update.stock.toFirestore());
      }

      transaction.set(requestRef, {
        'referenceId': referenceId,
        'requesterUid': requesterUid,
        'requesterName':
            _readString(userData, ['name']) ??
            currentUser?.displayName ??
            'Student',
        'requesterEmail':
            _readString(userData, ['email']) ?? currentUser?.email ?? '',
        'matricNumber': _readString(userData, ['matricNumber']) ?? '',
        'status': RentalRequestStatus.pending.name,
        'submittedAt': FieldValue.serverTimestamp(),
        'decidedAt': null,
        'decidedByUid': null,
        'returnedAt': null,
        'returnedByUid': null,
        'items': requestItems
            .map((item) => item.toMap())
            .toList(growable: false),
      });
    });

    return referenceId;
  }

  Future<void> approveRequest({
    required String requestId,
    required String adminUid,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final requestRef = _requestsRef.doc(requestId);
      final requestDoc = await transaction.get(requestRef);

      if (!requestDoc.exists) {
        throw Exception('Request was not found.');
      }

      final request = RentalRequest.fromDocument(requestDoc);
      if (!request.isPending) {
        throw Exception('Request has already been decided.');
      }

      final stockUpdates = <_StockUpdate>[];

      for (final item in request.items) {
        final itemRef = _inventoryRef.doc(item.itemId);
        final itemDoc = await transaction.get(itemRef);

        if (!itemDoc.exists) {
          throw Exception('${item.name} is no longer in inventory.');
        }

        final itemData = itemDoc.data() ?? <String, dynamic>{};
        final isConsumable = _readString(itemData, ['type']) == 'consumable';
        if (isConsumable) {
          continue;
        }

        final stock = _readStock(itemData);
        if (stock.holdingAmount < item.quantity) {
          throw Exception('Holding amount is too low for ${item.name}.');
        }

        stockUpdates.add(
          _StockUpdate(
            ref: itemRef,
            stock: stock.copyWith(
              holdingAmount: stock.holdingAmount - item.quantity,
              rentedAmount: stock.rentedAmount + item.quantity,
            ),
          ),
        );
      }

      for (final update in stockUpdates) {
        transaction.update(update.ref, update.stock.toFirestore());
      }

      transaction.update(requestRef, {
        'status': RentalRequestStatus.approved.name,
        'decidedAt': FieldValue.serverTimestamp(),
        'decidedByUid': adminUid,
      });
    });
  }

  Future<void> rejectRequest({
    required String requestId,
    required String adminUid,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final requestRef = _requestsRef.doc(requestId);
      final requestDoc = await transaction.get(requestRef);

      if (!requestDoc.exists) {
        throw Exception('Request was not found.');
      }

      final request = RentalRequest.fromDocument(requestDoc);
      if (!request.isPending) {
        throw Exception('Request has already been decided.');
      }

      final stockUpdates = <_StockUpdate>[];

      for (final item in request.items) {
        final itemRef = _inventoryRef.doc(item.itemId);
        final itemDoc = await transaction.get(itemRef);

        if (!itemDoc.exists) {
          throw Exception('${item.name} is no longer in inventory.');
        }

        final itemData = itemDoc.data() ?? <String, dynamic>{};
        final isConsumable = _readString(itemData, ['type']) == 'consumable';
        if (isConsumable) {
          continue;
        }

        final stock = _readStock(itemData);
        if (stock.holdingAmount < item.quantity) {
          throw Exception('Holding amount is too low for ${item.name}.');
        }

        stockUpdates.add(
          _StockUpdate(
            ref: itemRef,
            stock: stock.copyWith(
              availableAmount: stock.availableAmount + item.quantity,
              holdingAmount: stock.holdingAmount - item.quantity,
            ),
          ),
        );
      }

      for (final update in stockUpdates) {
        transaction.update(update.ref, update.stock.toFirestore());
      }

      transaction.update(requestRef, {
        'status': RentalRequestStatus.rejected.name,
        'decidedAt': FieldValue.serverTimestamp(),
        'decidedByUid': adminUid,
      });
    });
  }

  Future<void> returnRequest({
    required String requestId,
    required String adminUid,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final requestRef = _requestsRef.doc(requestId);
      final requestDoc = await transaction.get(requestRef);

      if (!requestDoc.exists) {
        throw Exception('Request was not found.');
      }

      final request = RentalRequest.fromDocument(requestDoc);
      if (request.status != RentalRequestStatus.approved) {
        throw Exception('Only approved requests can be returned.');
      }

      final stockUpdates = <_StockUpdate>[];

      for (final item in request.items) {
        final itemRef = _inventoryRef.doc(item.itemId);
        final itemDoc = await transaction.get(itemRef);

        if (!itemDoc.exists) {
          throw Exception('${item.name} is no longer in inventory.');
        }

        final itemData = itemDoc.data() ?? <String, dynamic>{};
        final isConsumable = _readString(itemData, ['type']) == 'consumable';
        if (isConsumable) {
          continue;
        }

        final stock = _readStock(itemData);
        if (stock.rentedAmount < item.quantity) {
          throw Exception('Rented amount is too low for ${item.name}.');
        }

        stockUpdates.add(
          _StockUpdate(
            ref: itemRef,
            stock: stock.copyWith(
              availableAmount: stock.availableAmount + item.quantity,
              rentedAmount: stock.rentedAmount - item.quantity,
            ),
          ),
        );
      }

      for (final update in stockUpdates) {
        transaction.update(update.ref, update.stock.toFirestore());
      }

      transaction.update(requestRef, {
        'status': RentalRequestStatus.returned.name,
        'returnedAt': FieldValue.serverTimestamp(),
        'returnedByUid': adminUid,
      });
    });
  }

  List<RentalRequest> _mapSortedRequests(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final requests = snapshot.docs
        .map(RentalRequest.fromDocument)
        .toList(growable: true);

    requests.sort((a, b) {
      final left = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });

    return requests;
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
    return _readNullableInt(data, keys) ?? 0;
  }

  int? _readNullableInt(Map<String, dynamic> data, List<String> keys) {
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

  _InventoryStock _readStock(Map<String, dynamic> data) {
    final legacyQuantity = _readInt(data, ['Quantity', 'quantity']);
    final totalAmount =
        _readNullableInt(data, ['totalAmount']) ?? legacyQuantity;
    final holdingAmount = _readNullableInt(data, ['holdingAmount']) ?? 0;
    final rentedAmount = _readNullableInt(data, ['rentedAmount']) ?? 0;
    final computedAvailable = totalAmount - holdingAmount - rentedAmount;
    final availableAmount =
        _readNullableInt(data, ['availableAmount']) ??
        computedAvailable.clamp(0, totalAmount).toInt();

    return _InventoryStock(
      totalAmount: totalAmount,
      availableAmount: availableAmount,
      holdingAmount: holdingAmount,
      rentedAmount: rentedAmount,
    );
  }
}

class _StockUpdate {
  const _StockUpdate({required this.ref, required this.stock});

  final DocumentReference<Map<String, dynamic>> ref;
  final _InventoryStock stock;
}

class _InventoryStock {
  const _InventoryStock({
    required this.totalAmount,
    required this.availableAmount,
    required this.holdingAmount,
    required this.rentedAmount,
  });

  final int totalAmount;
  final int availableAmount;
  final int holdingAmount;
  final int rentedAmount;

  _InventoryStock copyWith({
    int? totalAmount,
    int? availableAmount,
    int? holdingAmount,
    int? rentedAmount,
  }) {
    return _InventoryStock(
      totalAmount: totalAmount ?? this.totalAmount,
      availableAmount: availableAmount ?? this.availableAmount,
      holdingAmount: holdingAmount ?? this.holdingAmount,
      rentedAmount: rentedAmount ?? this.rentedAmount,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalAmount': totalAmount,
      'availableAmount': availableAmount,
      'holdingAmount': holdingAmount,
      'rentedAmount': rentedAmount,
      'Quantity': totalAmount,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
