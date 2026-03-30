import 'product_variant.dart';

class Product {
  final int id;
  final String name;
  final String sku;
  final String? description;
  final Category? category;
  final Supplier? supplier;
  final Brand? brand;
  final int quantity;
  final int minStock;
  final double costPrice;
  final double sellingPrice;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final List<ProductOption> options;
  final List<ProductVariant> variants;
  final int viewCount;
  final String? imageUrl;
  final List<String> images;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.description,
    this.category,
    this.supplier,
    this.brand,
    required this.quantity,
    required this.minStock,
    required this.costPrice,
    required this.sellingPrice,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.options = const [],
    this.variants = const [],
    this.viewCount = 0,
    this.imageUrl,
    this.images = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Utility to parse double safely
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Product(
      id: json['id'] is int ? json['id'] : (json['_id'] is int ? json['_id'] : int.tryParse(json['id']?.toString() ?? json['_id']?.toString() ?? '0') ?? 0),
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category'] != null && json['category'] is Map<String, dynamic> ? Category.fromJson(json['category']) : null,
      supplier: json['supplier'] != null && json['supplier'] is Map<String, dynamic> ? Supplier.fromJson(json['supplier']) : null,
      brand: json['brand'] != null && json['brand'] is Map<String, dynamic> ? Brand.fromJson(json['brand']) : null,
      quantity: json['quantity'] is int ? json['quantity'] : (int.tryParse(json['quantity']?.toString() ?? '0') ?? 0),
      minStock: json['minStock'] is int ? json['minStock'] : (int.tryParse(json['minStock']?.toString() ?? '0') ?? 0),
      costPrice: parseDouble(json['costPrice']),
      sellingPrice: parseDouble(json['sellingPrice'] ?? json['price'] ?? json['unitPrice']),
      status: json['status']?.toString() ?? 'ACTIVE',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => ProductOption.fromJson(e))
              .toList() ??
          [],
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e))
              .toList() ??
          [],
      viewCount: json['viewCount'] is int ? json['viewCount'] : (int.tryParse(json['viewCount']?.toString() ?? '0') ?? 0),
      imageUrl: json['imageUrl']?.toString(),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'description': description,
      'category': category?.toJson(),
      'supplier': supplier?.toJson(),
      'brand': brand?.toJson(),
      'quantity': quantity,
      'minStock': minStock,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'options': options.map((e) => e.toJson()).toList(),
      'variants': variants.map((e) => e.toJson()).toList(),
      'imageUrl': imageUrl,
    };
  }
}

class Category {
  final String id;
  final String name;
  final String? description;

  Category({
    required this.id,
    required this.name,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class Supplier {
  final String id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;

  Supplier({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      contactPerson: json['contactPerson'],
      phone: json['phone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
    };
  }
}

class Brand {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;

  Brand({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      logoUrl: json['logoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
    };
  }
}

class ProductOption {
  final String name;
  final List<String> values;

  ProductOption({
    required this.name,
    this.values = const [],
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      name: json['name']?.toString() ?? '',
      values: (json['values'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'values': values,
    };
  }
}
