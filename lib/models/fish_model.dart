class FishModel {
  final String id;
  final String name;
  final String fishType;
  final String category;
  final String quality;
  final String unit;
  final double defaultPrice;
  final String description;
  final String imageUrl;

  FishModel({
    required this.id,
    required this.name,
    required this.fishType,
    this.category = 'Fresh Fish',
    this.quality = 'Premium',
    this.unit = 'Kg',
    this.defaultPrice = 0.0,
    this.description = '',
    this.imageUrl = '',
  });

  factory FishModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return FishModel(
      id: map['id']?.toString() ?? docId ?? '',
      name: map['name']?.toString() ?? map['fishName']?.toString() ?? '',
      fishType: map['fishType']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Fresh Fish',
      quality: map['quality']?.toString() ?? 'Premium',
      unit: map['unit']?.toString() ?? 'Kg',
      defaultPrice: (map['price'] as num?)?.toDouble() ?? 0.0,
      description: map['description']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fishName': name,
      'fishType': fishType,
      'category': category,
      'quality': quality,
      'unit': unit,
      'price': defaultPrice,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
