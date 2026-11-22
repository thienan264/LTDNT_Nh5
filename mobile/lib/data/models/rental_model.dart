enum RentalStatus {
  pending,
  approved,
  active,
  returned,
  overdue,
  cancelled;

  String get label {
    switch (this) {
      case RentalStatus.pending:
        return 'Chờ duyệt';
      case RentalStatus.approved:
        return 'Đã duyệt, chờ bàn giao';
      case RentalStatus.active:
        return 'Đang hiệu lực';
      case RentalStatus.returned:
        return 'Đã hoàn trả';
      case RentalStatus.overdue:
        return 'Quá hạn';
      case RentalStatus.cancelled:
        return 'Đã hủy đơn';
    }
  }

  static RentalStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case '0':
        return RentalStatus.pending;
      case 'RETURNED':
      case '3':
        return RentalStatus.returned;
      case 'OVERDUE':
        return RentalStatus.overdue;
      case 'CANCELLED':
      case '4':
        return RentalStatus.cancelled;
      case 'APPROVED':
      case '1':
        return RentalStatus.approved;
      case 'RENTING':
      case 'ACTIVE':
      case '2':
      default:
        return RentalStatus.active;
    }
  }
}

class RentalModel {
  final int id;
  final String contractCode;
  final String unitName;
  final String unitAddress;
  final String contactPerson;
  final String phoneNumber;
  final DateTime startDate;
  final DateTime expectedEndDate;
  final DateTime? actualEndDate;
  final double totalDeposit;
  final RentalStatus status;
  final List<String> deviceNames;
  final List<DateTime?> deviceReturnDates;
  final String? notes;
  final bool isOverdue;
  final int daysOverdue;
  final bool isDueSoon;
  final double estimatedTotalCost;

  RentalModel({
    required this.id,
    required this.contractCode,
    required this.unitName,
    required this.unitAddress,
    required this.contactPerson,
    required this.phoneNumber,
    required this.startDate,
    required this.expectedEndDate,
    this.actualEndDate,
    required this.totalDeposit,
    required this.status,
    required this.deviceNames,
    this.deviceReturnDates = const [],
    this.notes,
    this.isOverdue = false,
    this.daysOverdue = 0,
    this.isDueSoon = false,
    this.estimatedTotalCost = 0.0,
  });

  factory RentalModel.fromJson(Map<String, dynamic> json) {
    List<String> names = [];
    if (json['items'] is List) {
      names = (json['items'] as List)
          .map(
            (i) =>
                (i['deviceName'] ?? i['device_name'] ?? 'Thiết bị').toString(),
          )
          .toList();
    } else if (json['deviceNames'] is List) {
      names = (json['deviceNames'] as List).map((e) => e.toString()).toList();
    } else if (json['device_names'] is List) {
      names = (json['device_names'] as List).map((e) => e.toString()).toList();
    }

    final start =
        DateTime.tryParse(
          json['startDate']?.toString() ?? json['start_date']?.toString() ?? '',
        ) ??
        DateTime.now();
    final end =
        DateTime.tryParse(
          json['expectedEndDate']?.toString() ??
              json['expected_end_date']?.toString() ??
              '',
        ) ??
        DateTime.now().add(const Duration(days: 7));
    final actualEnd =
        json['actualEndDate'] != null || json['actual_end_date'] != null
        ? DateTime.tryParse(
            json['actualEndDate']?.toString() ??
                json['actual_end_date']?.toString() ??
                '',
          )
        : null;

    final deposit =
        ((json['totalDeposit'] ?? json['total_deposit'] ?? 0) as num)
            .toDouble();
    final totalCost =
        ((json['totalAmount'] ??
                    json['total_amount'] ??
                    json['estimated_total_cost'] ??
                    0)
                as num)
            .toDouble();

    final statusStr = (json['status'] ?? 'Active').toString();
    final status = RentalStatus.fromString(statusStr);

    final now = DateTime.now();
    final isOverdue = status == RentalStatus.active && end.isBefore(now);
    final daysOverdue = isOverdue ? now.difference(end).inDays : 0;
    final isDueSoon =
        status == RentalStatus.active &&
        !isOverdue &&
        end.isBefore(now.add(const Duration(days: 3)));

    return RentalModel(
      id: json['id'] as int? ?? 0,
      contractCode:
          (json['contractCode'] ?? json['contract_code'] ?? 'HDT') as String,
      unitName:
          (json['unitName'] ?? json['unit_name'] ?? 'Đơn vị cho thuê')
              as String,
      unitAddress:
          (json['shippingAddress'] ??
                  json['unitAddress'] ??
                  json['unit_address'] ??
                  'Tại kho đơn vị')
              as String,
      contactPerson:
          (json['userName'] ??
                  json['contactPerson'] ??
                  json['contact_person'] ??
                  'Khách thuê')
              as String,
      phoneNumber:
          (json['phoneNumber'] ?? json['phone_number'] ?? '') as String,
      startDate: start,
      expectedEndDate: end,
      actualEndDate: actualEnd,
      totalDeposit: deposit,
      status: status,
      deviceNames: names,
      deviceReturnDates: json['items'] is List
          ? (json['items'] as List)
                .map(
                  (i) => DateTime.tryParse(
                    i['actualReturnDate']?.toString() ?? '',
                  ),
                )
                .toList()
          : [],
      notes: json['notes'] as String?,
      isOverdue: isOverdue,
      daysOverdue: daysOverdue,
      isDueSoon: isDueSoon,
      estimatedTotalCost: totalCost,
    );
  }
}
