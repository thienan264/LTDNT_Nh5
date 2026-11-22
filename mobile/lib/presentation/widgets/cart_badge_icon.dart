import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/datasources/cart_service.dart';
import '../screens/cart/cart_screen.dart';

class CartBadgeIcon extends StatelessWidget {
  const CartBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: CartService.cartNotifier,
      builder: (context, items, _) {
        final count = items.length;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: AppColors.primary,
              ),
              tooltip: 'Giỏ thiết bị thuê',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
