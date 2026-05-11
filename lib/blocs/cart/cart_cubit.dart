import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/cart_item.dart';

class CartCubit extends Cubit<List<CartItem>> {
  CartCubit() : super([]);

  void addItem(CartItem item) {
    final existingIndex =
        state.indexWhere((e) => e.id == item.id);

    if (existingIndex != -1) {
      state[existingIndex].quantity += item.quantity;
      emit(List.from(state));
    } else {
      emit([...state, item]);
    }
  }

  void removeItem(String id) {
    emit(state.where((e) => e.id != id).toList());
  }

  void increaseQty(String id) {
    final index = state.indexWhere((e) => e.id == id);
    if (index != -1) {
      state[index].quantity++;
      emit(List.from(state));
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