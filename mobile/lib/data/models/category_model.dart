import '../../core/constants/api_constants.dart';

class CategoryModel {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final int deviceCount;
  final DateTime? createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    this.deviceCount = 0,
    this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String rawImage = (json['imageUrl'] ?? json['image_url'] ?? '') as String;
    if (rawImage.startsWith('/')) {
      rawImage = '${ApiConstants.baseHost}$rawImage';
    }

    return CategoryModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      imageUrl: rawImage,
      deviceCount: json['deviceCount'] is int
          ? json['deviceCount'] as int
          : (json['device_count'] is int
                ? json['device_count'] as int
                : int.tryParse(
                        (json['deviceCount'] ?? json['device_count'] ?? '0')
                            .toString(),
                      ) ??
                      0),
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.tryParse(
              (json['createdAt'] ?? json['created_at']).toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'device_count': deviceCount,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    int? deviceCount,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      deviceCount: deviceCount ?? this.deviceCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
