import 'package:flutter_test/flutter_test.dart';
import 'package:techcare_app/models/inventory_item.dart';

void main() {
  group('InventoryItem stock counters', () {
    test('uses legacy Quantity as total and available fallback', () {
      final item = InventoryItem.fromData(
        id: 'item-1',
        data: {'Name': 'Camera', 'Quantity': 5},
      );

      expect(item.totalAmount, 5);
      expect(item.availableAmount, 5);
      expect(item.holdingAmount, 0);
      expect(item.rentedAmount, 0);
      expect(item.quantity, 5);
    });

    test('reads explicit stock counters', () {
      final item = InventoryItem.fromData(
        id: 'item-2',
        data: {
          'Name': 'Tripod',
          'totalAmount': 10,
          'availableAmount': 6,
          'holdingAmount': 1,
          'rentedAmount': 3,
        },
      );

      expect(item.totalAmount, 10);
      expect(item.availableAmount, 6);
      expect(item.holdingAmount, 1);
      expect(item.rentedAmount, 3);
    });
  });

  group('InventoryItem Firestore serialization', () {
    test('omits stock fields for consumable items', () {
      final data = _item(amountType: 'consumable').toFirestore();

      expect(data['amountType'], 'consumable');
      expect(data, isNot(contains('totalAmount')));
      expect(data, isNot(contains('availableAmount')));
      expect(data, isNot(contains('holdingAmount')));
      expect(data, isNot(contains('rentedAmount')));
      expect(data, isNot(contains('Quantity')));
    });

    test('keeps all stock fields for unit items', () {
      final data = _item(amountType: 'unit').toFirestore();

      expect(data['amountType'], 'unit');
      expect(data['totalAmount'], 10);
      expect(data['availableAmount'], 6);
      expect(data['holdingAmount'], 1);
      expect(data['rentedAmount'], 3);
      expect(data['Quantity'], 10);
    });
  });
}

InventoryItem _item({required String amountType}) {
  return InventoryItem(
    id: '',
    code: 'ITEM001',
    name: 'Test Item',
    category: 'Test Category',
    subCategory: 'Test Sub-category',
    description: 'Test description',
    location: 'Test location',
    totalAmount: 10,
    availableAmount: 6,
    holdingAmount: 1,
    rentedAmount: 3,
    imageUrl: '',
    timestamp: null,
    amountType: amountType,
  );
}
