import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/cart_service.dart';
import '../../data/models/device_model.dart';
import '../../data/repositories/member_repository.dart';

class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onTap;
  final List<Widget>? adminActions;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
    this.adminActions,
  });

  Color _getStatusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.available:
        return AppColors.statusAvailable;
      case DeviceStatus.rented:
        return AppColors.statusRented;
      case DeviceStatus.maintenance:
        return AppColors.statusMaintenance;
      case DeviceStatus.broken:
        return AppColors.statusBroken;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        (device.imageUrl != null && device.imageUrl!.isNotEmpty)
                        ? Image.network(
                            device.imageUrl!.startsWith('http')
                                ? device.imageUrl!
                                : '${ApiConstants.baseHost}${device.imageUrl}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.build_circle_outlined,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                          )
                        : const Icon(
                            Icons.build_circle_outlined,
                            color: AppColors.primary,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mã Serial: ${device.serialNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(device.status)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      MemberRepository.isAdmin
                          ? device.status.label
                          : device.rentalLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(device.status),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giá thuê: ${currencyFormatter.format(device.rentalPricePerDay)}/ngày',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        if (device.currentUnitName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Tại: ${device.currentUnitName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (adminActions != null)
                    Row(mainAxisSize: MainAxisSize.min, children: adminActions!)
                  else if (device.status == DeviceStatus.available)
                    IconButton.filledTonal(
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: AppColors.primary,
                      ),
                      tooltip: 'Thêm vào giỏ thiết bị thuê',
                      onPressed: () {
                        CartService.addToCart(device);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã thêm "${device.name}" vào giỏ thuê',
                            ),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
