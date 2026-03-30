class ProductVariant {
  final int id;
  final String variantName;
  final String sku;
  final List<String> optionValues;
  final int stockQuantity;
  final double additionalPrice;
  final String? imageUrl;
  final String status;

  ProductVariant({
    required this.id,
    required this.variantName,
    required this.sku,
    this.optionValues = const [],
    required this.stockQuantity,
    this.additionalPrice = 0.0,
    this.imageUrl,
    required this.status,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] ?? 0,
      variantName: json['variantName'] ?? '',
      sku: json['sku'] ?? '',
      optionValues: (json['optionValues'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      stockQuantity: json['stockQuantity'] ?? 0,
      additionalPrice: (json['additionalPrice'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'variantName': variantName,
      'sku': sku,
      'optionValues': optionValues,
      'stockQuantity': stockQuantity,
      'additionalPrice': additionalPrice,
      'imageUrl': imageUrl,
      'status': status,
    };
  }
}
