import '../product/product.dart';
import '../product/product_variant.dart';

class CartItem {
  final int id;
  final Product product;
  final int quantity;
  final double price;
  final double subtotal;

  final int? variantId;
  final String? variantName;
  final String? variantAttributes;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.variantId,
    this.variantName,
    this.variantAttributes,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      product: json['product'] != null 
          ? Product.fromJson(json['product'])
          : Product(
              id: json['productId'] ?? 0,
              name: json['productName'] ?? 'Unknown Product',
              sku: json['productSku'] ?? '',
              quantity: json['productQuantity'] ?? 999, // Fallback to 999 if not provided to avoid blocking UI
              minStock: 0,
              costPrice: 0,
              sellingPrice: (json['unitPrice'] ?? 0).toDouble(),
              status: 'ACTIVE',
              variants: (json['productVariants'] as List<dynamic>?)
                  ?.map((e) => ProductVariant.fromJson(e))
                  .toList() ??
                  [],
            ),
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? json['unitPrice'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      variantId: json['variantId'],
      variantName: json['variantName'],
      variantAttributes: json['variantAttributes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }

  CartItem copyWith({
    int? id,
    Product? product,
    int? quantity,
    double? price,
    double? subtotal,
    int? variantId,
    String? variantName,
    String? variantAttributes,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      variantAttributes: variantAttributes ?? this.variantAttributes,
    );
  }
}

class CartItemRequest {
  final int productId;
  final int quantity;
  final int? variantId;

  CartItemRequest({
    required this.productId,
    required this.quantity,
    this.variantId,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      if (variantId != null) 'variantId': variantId,
    };
  }
}
