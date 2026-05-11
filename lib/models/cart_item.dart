class CartItem {
  final String id;
  final String name;
  final String? image;
  final String code;
  final int maxQuantity;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    this.image,
    required this.code,
    required this.quantity,
    required this.maxQuantity,
  });
}
