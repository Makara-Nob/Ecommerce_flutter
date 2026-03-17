import 'order_item.dart';

class Order {
  final int id;
  final int userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String? deliveryAddress;
  final String? deliveryPhone;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // PayWay specific fields returned in checkout response
  final Map<String, dynamic>? paywayPayload;
  final String? paywayApiUrl;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.deliveryAddress,
    this.deliveryPhone,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.paywayPayload,
    this.paywayApiUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Determine if the JSON is wrapped in { "order": {...}, "paywayPayload": {...} }
    final orderJson = json.containsKey('order') ? json['order'] as Map<String, dynamic> : json;
    
    return Order(
      id: orderJson['id'] ?? orderJson['_id'] ?? 0,
      userId: orderJson['userId'] ?? 0,
      items: (orderJson['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      totalAmount: (orderJson['totalAmount'] ?? 0).toDouble(),
      status: orderJson['status'] ?? '',
      deliveryAddress: orderJson['deliveryAddress'] ?? orderJson['shippingAddress'],
      deliveryPhone: orderJson['deliveryPhone'],
      notes: orderJson['notes'],
      createdAt: orderJson['createdAt'] != null ? DateTime.parse(orderJson['createdAt']) : null,
      updatedAt: orderJson['updatedAt'] != null ? DateTime.parse(orderJson['updatedAt']) : null,
      paywayPayload: json['paywayPayload'] as Map<String, dynamic>?,
      paywayApiUrl: json['paywayApiUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'deliveryPhone': deliveryPhone,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'paywayPayload': paywayPayload,
      'paywayApiUrl': paywayApiUrl,
    };
  }
}

class OrderRequest {
  final String? shippingAddress;
  final String? deliveryPhone;
  final String? notes;
  final String paymentMethod;
  final List<Map<String, dynamic>> items;

  OrderRequest({
    this.shippingAddress,
    this.deliveryPhone,
    this.notes,
    this.paymentMethod = 'CASH',
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'shippingAddress': shippingAddress,
      'deliveryPhone': deliveryPhone,
      'notes': notes,
      'paymentMethod': paymentMethod,
      'items': items,
    };
  }
}

class OrderListResponse {
  final List<Order> orders;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  OrderListResponse({
    required this.orders,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    return OrderListResponse(
      orders: (json['content'] as List?)
              ?.map((item) => Order.fromJson(item))
              .toList() ??
          [],
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['pageNo'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
    );
  }
}
