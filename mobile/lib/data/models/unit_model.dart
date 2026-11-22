class UnitModel {
  final int id;
  final String name;
  final String address;
  final String phoneNumber;
  final String contactPerson;
  final String? email;

  UnitModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.contactPerson,
    this.email,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      phoneNumber:
          (json['phoneNumber'] ?? json['phone_number'] ?? '') as String,
      contactPerson:
          (json['contactPerson'] ?? json['contact_person'] ?? 'Người phụ trách')
              as String,
      email: json['email'] as String?,
    );
  }
}
