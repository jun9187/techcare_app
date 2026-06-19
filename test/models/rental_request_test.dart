import 'package:flutter_test/flutter_test.dart';
import 'package:techcare_app/models/rental_request.dart';

void main() {
  group('RentalRequestItem', () {
    test('parses item maps with string quantity', () {
      final item = RentalRequestItem.fromMap({
        'itemId': 'item-1',
        'code': 'CAM-01',
        'name': 'Camera',
        'imageUrl': 'https://example.com/camera.jpg',
        'quantity': '2',
      });

      expect(item.itemId, 'item-1');
      expect(item.code, 'CAM-01');
      expect(item.name, 'Camera');
      expect(item.imageUrl, 'https://example.com/camera.jpg');
      expect(item.quantity, 2);
    });
  });

  group('rentalRequestStatusFromString', () {
    test('normalizes supported status values', () {
      expect(
        rentalRequestStatusFromString('pending'),
        RentalRequestStatus.pending,
      );
      expect(rentalRequestStatusFromString('A'), RentalRequestStatus.approved);
      expect(
        rentalRequestStatusFromString('rejected'),
        RentalRequestStatus.rejected,
      );
      expect(
        rentalRequestStatusFromString('returned'),
        RentalRequestStatus.returned,
      );
    });
  });
}
