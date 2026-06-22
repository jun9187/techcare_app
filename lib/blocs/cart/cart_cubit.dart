import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/cart_item.dart';

class CartCubit extends Cubit<List<CartItem>> {
  CartCubit() : super([]);

  void addItem(CartItem item) {
    final existingIndex = state.indexWhere((e) => e.id == item.id);
    final nextItems = List<CartItem>.from(state);

    if (existingIndex != -1) {
      final existingItem = nextItems[existingIndex];
      final maxQty = existingItem.isConsumable ? 9999 : existingItem.maxQuantity;
      existingItem.quantity =
          (existingItem.quantity + item.quantity).clamp(1, maxQty);
      emit(nextItems);
    } else {
      final maxQty = item.isConsumable ? 9999 : item.maxQuantity;
      item.quantity = item.quantity.clamp(1, maxQty);
      emit([...nextItems, item]);
    }
  }

  void removeItem(String id) {
    emit(state.where((e) => e.id != id).toList());
  }

  void increaseQty(String id) {
    final index = state.indexWhere((e) => e.id == id);
    if (index != -1) {
      final nextItems = List<CartItem>.from(state);
      final item = nextItems[index];
      final maxQty = item.isConsumable ? 9999 : item.maxQuantity;
      if (item.quantity >= maxQty) return;
      item.quantity++;
      emit(nextItems);
    }
  }

  void decreaseQty(String id) {
    final index = state.indexWhere((e) => e.id == id);
    if (index != -1 && state[index].quantity > 1) {
      state[index].quantity--;
      emit(List.from(state));
    }
  }

  void clearCart() {
    emit([]);
  }
}
