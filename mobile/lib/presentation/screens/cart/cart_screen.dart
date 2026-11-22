import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/cart_service.dart';
import '../../../data/models/cart_item_model.dart';
import '../devices/device_list_screen.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Giỏ Thiết bị Thuê'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          ValueListenableBuilder<List<CartItemModel>>(
            valueListenable: CartService.cartNotifier,
            builder: (context, items, _) {
              if (items.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  color: Color.fromARGB(255, 216, 14, 14),
                ),
                tooltip: 'Xóa tất cả',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xóa giỏ hàng'),
                      content: const Text(
                        'Bạn có chắc chắn muốn xóa toàn bộ thiết bị khỏi giỏ hàng?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Hủy'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusBroken,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            CartService.clearCart();
                          },
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<CartItemModel>>(
        valueListenable: CartService.cartNotifier,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Giỏ hàng của bạn đang trống',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hãy chọn các máy móc, thiết bị sẵn sàng để đặt thuê',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Xem danh mục thiết bị'),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DeviceListScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final totalRent = CartService.totalAmount;
          final totalDeposit = CartService.totalDeposit;

          return Column(
            children: [
              // List of cart items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final d = item.device;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.precision_manufacturing_outlined,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Mã Serial: ${d.serialNumber} • ${d.categoryName}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${currencyFormat.format(d.rentalPricePerDay)} / ngày',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.statusBroken,
                                  size: 20,
                                ),
                                tooltip: 'Xóa khỏi giỏ',
                                onPressed: () =>
                                    CartService.removeFromCart(d.id),
                              ),
                            ],
                          ),
                          const Divider(height: 20),

                          // Controls: Số ngày thuê & Tổng tiền máy này
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Số ngày thuê:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        InkWell(
                                          onTap: item.rentalDays > 1
                                              ? () => CartService.updateDays(
                                                  d.id,
                                                  item.rentalDays - 1,
                                                )
                                              : null,
                                          borderRadius:
                                              const BorderRadius.horizontal(
                                                left: Radius.circular(8),
                                              ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            child: const Icon(
                                              Icons.remove,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          color: AppColors.background,
                                          child: Text(
                                            '${item.rentalDays} ngày',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => CartService.updateDays(
                                            d.id,
                                            item.rentalDays + 1,
                                          ),
                                          borderRadius:
                                              const BorderRadius.horizontal(
                                                right: Radius.circular(8),
                                              ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                currencyFormat.format(item.itemTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom summary card & Checkout button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng tiền thuê tạm tính:',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          currencyFormat.format(totalRent),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tiền cọc cam kết (30%):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currencyFormat.format(totalDeposit),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        label: Text(
                          'Tiến hành Đặt thuê (${items.length} máy)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(cartItems: items),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
