import 'cart_item.dart';

class Cart {
  final int id;
  final int userId;
  final List<CartItem> items;
  final double totalAmount;

  Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      items: (json['items'] as List?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
    };
  }
  
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Cart copyWith({
    int? id,
    int? userId,
    List<CartItem>? items,
    double? totalAmount,
  }) {
    return Cart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}
