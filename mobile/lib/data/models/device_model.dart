import '../../core/constants/api_constants.dart';

enum DeviceStatus {
  available,
  rented,
  maintenance,
  broken;

  String get label {
    switch (this) {
      case DeviceStatus.available:
        return 'Sẵn sàng';
      case DeviceStatus.rented:
        return 'Đang cho thuê';
      case DeviceStatus.maintenance:
        return 'Bảo trì';
      case DeviceStatus.broken:
        return 'Hỏng hóc';
    }
  }

  static DeviceStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'RENTED':
      case '1':
        return DeviceStatus.rented;
      case 'MAINTENANCE':
      case '2':
        return DeviceStatus.maintenance;
      case 'BROKEN':
      case '3':
        return DeviceStatus.broken;
      case 'AVAILABLE':
      case '0':
      default:
        return DeviceStatus.available;
    }
  }
}

class DeviceModel {
  final bool isRentedByMe;
  final String? myRentalStatus;
  final int id;
  final String serialNumber;
  final String name;
  final String categoryName;
  final int? categoryId;
  final DeviceStatus status;
  final double rentalPricePerDay;
  final String qrCode;
  final String? imageUrl;
  final String? currentUnitName;

  DeviceModel({
    this.isRentedByMe = false,
    this.myRentalStatus,
    required this.id,
    required this.serialNumber,
    required this.name,
    required this.categoryName,
    this.categoryId,
    required this.status,
    required this.rentalPricePerDay,
    required this.qrCode,
    this.imageUrl,
    this.currentUnitName,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    String? rawImage = (json['imageUrl'] ?? json['image_url']) as String?;
    if (rawImage != null && rawImage.startsWith('/')) {
      rawImage = '${ApiConstants.baseHost}$rawImage';
    }

    return DeviceModel(
      isRentedByMe: json['isRentedByMe'] == true,
      myRentalStatus: json['myRentalStatus']?.toString(),
      id: json['id'] as int? ?? 0,
      serialNumber:
          (json['serialNumber'] ?? json['serial_number'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      categoryName:
          (json['categoryName'] ?? json['category_name'] ?? 'Chung') as String,
      categoryId: json['categoryId'] ?? json['category_id'] as int?,
      status: DeviceStatus.fromString(
        (json['status'] ?? 'AVAILABLE').toString(),
      ),
      rentalPricePerDay:
          ((json['rentalPricePerDay'] ?? json['rental_price_per_day'] ?? 0)
                  as num)
              .toDouble(),
      qrCode: (json['qrCode'] ?? json['qr_code'] ?? '') as String,
      imageUrl: rawImage,
      currentUnitName:
          (json['unitName'] ??
                  json['currentUnitName'] ??
                  json['current_unit_name'])
              as String?,
    );
  }

  String get rentalLabel {
    if (isRentedByMe) {
      return myRentalStatus == 'Renting' || myRentalStatus == '2'
          ? 'Bạn đang thuê'
          : 'Bạn đã đặt thuê';
    }
    return status == DeviceStatus.rented ? 'Đã có khách thuê' : status.label;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serial_number': serialNumber,
      'name': name,
      'category_name': categoryName,
      'category_id': categoryId,
      'status': status.name.toUpperCase(),
      'rental_price_per_day': rentalPricePerDay,
      'qr_code': qrCode,
      'image_url': imageUrl,
      'current_unit_name': currentUnitName,
    };
  }
}
