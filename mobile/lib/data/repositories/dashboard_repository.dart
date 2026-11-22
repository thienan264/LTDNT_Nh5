import 'device_repository.dart';
import 'rental_repository.dart';
import '../models/device_model.dart';
import '../models/rental_model.dart';

class DashboardRepository {
  static Future<Map<String, dynamic>> getDashboardStats() async {
    var devices = await DeviceRepository.getDevices();
    var rentals = await RentalRepository.getRentals();
    var active = rentals.where((r) => r.status == RentalStatus.active).toList();
    return {
      'total_devices': devices.length,
      'rented_count': devices
          .where((d) => d.status == DeviceStatus.rented)
          .length,
      'available_count': devices
          .where((d) => d.status == DeviceStatus.available)
          .length,
      'maintenance_count': devices
          .where(
            (d) =>
                d.status == DeviceStatus.maintenance ||
                d.status == DeviceStatus.broken,
          )
          .length,
      'overdue_count': active.where((r) => r.isOverdue).length,
      'due_soon_count': active.where((r) => r.isDueSoon).length,
      'total_deposit_holding': active.fold<double>(
        0,
        (s, r) => s + r.totalDeposit,
      ),
      'estimated_revenue': rentals.fold<double>(
        0,
        (s, r) => s + r.estimatedTotalCost,
      ),
      'active_rentals': active.length,
      'is_live': true,
    };
  }
}
