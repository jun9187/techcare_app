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
}
