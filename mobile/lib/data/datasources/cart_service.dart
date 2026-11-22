import 'package:flutter/foundation.dart';

import '../models/cart_item_model.dart';
import '../models/device_model.dart';
import 'local_db_helper.dart';

class CartService {
  static final ValueNotifier<List<CartItemModel>> cartNotifier =
      ValueNotifier<List<CartItemModel>>([]);

  static List<CartItemModel> get items => List.unmodifiable(cartNotifier.value);

  static int get totalCount => cartNotifier.value.length;

  static double get totalAmount =>
      cartNotifier.value.fold<double>(0.0, (sum, item) => sum + item.itemTotal);

  static double get totalDeposit => cartNotifier.value.fold<double>(
    0.0,
    (sum, item) => sum + item.depositEstimated,
  );

  static bool isInCart(int deviceId) {
    return cartNotifier.value.any((item) => item.device.id == deviceId);
  }

  // Khởi tạo và nạp giỏ hàng từ SQLite khi mở ứng dụng
  static Future<void> loadCartFromLocalDb() async {
    try {
      final localItems = await LocalDbHelper.instance.getCartItems();
      cartNotifier.value = localItems;
    } catch (e) {
      debugPrint('[CartService] Error initializing cart from SQLite: $e');
    }
  }

  // Thêm thiết bị vào giỏ hàng (Đồng bộ SQLite)
  static bool addToCart(DeviceModel device, {int rentalDays = 7}) {
    final currentList = List<CartItemModel>.from(cartNotifier.value);
    final existingIndex = currentList.indexWhere(
      (item) => item.device.id == device.id,
    );

    int finalDays = rentalDays;
    if (existingIndex != -1) {
      finalDays = currentList[existingIndex].rentalDays + rentalDays;
      currentList[existingIndex].rentalDays = finalDays;
      cartNotifier.value = currentList;
    } else {
      currentList.add(CartItemModel(device: device, rentalDays: rentalDays));
      cartNotifier.value = currentList;
    }

    // Persist to SQLite
    LocalDbHelper.instance.saveCartItem(device, finalDays);
    return true;
  }

  // Cập nhật số ngày thuê trên giỏ hàng (Đồng bộ SQLite)
  static void updateDays(int deviceId, int days) {
    if (days < 1) return;
    final currentList = List<CartItemModel>.from(cartNotifier.value);
    final index = currentList.indexWhere((item) => item.device.id == deviceId);
    if (index != -1) {
      currentList[index].rentalDays = days;
      cartNotifier.value = currentList;
      LocalDbHelper.instance.updateCartDays(deviceId, days);
    }
  }

  // Xóa sản phẩm khỏi giỏ hàng (Đồng bộ SQLite)
  static void removeFromCart(int deviceId) {
    final currentList = List<CartItemModel>.from(cartNotifier.value);
    currentList.removeWhere((item) => item.device.id == deviceId);
    cartNotifier.value = currentList;
    LocalDbHelper.instance.removeCartItem(deviceId);
  }

  // Xóa toàn bộ giỏ hàng (Đồng bộ SQLite)
  static void clearCart() {
    cartNotifier.value = [];
    LocalDbHelper.instance.clearCart();
  }
}
