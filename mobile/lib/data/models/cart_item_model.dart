import 'device_model.dart';

class CartItemModel {
  final DeviceModel device;
  int rentalDays;
  int quantity;

  CartItemModel({required this.device, this.rentalDays = 7, this.quantity = 1});

  double get itemTotal => device.rentalPricePerDay * rentalDays * quantity;

  double get depositEstimated =>
      itemTotal * 0.3; // Tiền cọc ước tính 30% giá trị thuê
}
