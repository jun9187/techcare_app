class CartItem {
  final String id;
  final String name;
  final String? image;
  final String code;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    this.image,
    required this.code,
    required this.quantity,
  });
}