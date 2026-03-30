import '../models/api_response.dart';
import '../models/order/order.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  // Create order from cart
  Future<ApiResponse<Order>> createOrder({
    String? deliveryAddress,
    String? deliveryPhone,
    String? notes,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'ABA_PAYWAY',
    bool? isBuyNow,
  }) async {
    final request = OrderRequest(
      shippingAddress: deliveryAddress,
      deliveryPhone: deliveryPhone,
      notes: notes,
      items: items,
      paymentMethod: paymentMethod,
      isBuyNow: isBuyNow,
    );

    return await _apiService.post<Order>(
      ApiConstants.orders,
      body: request.toJson(),
      requiresAuth: true,
      fromJson: (json) => Order.fromJson(json),
    );
  }

  // Get my orders with pagination
  Future<ApiResponse<OrderListResponse>> getMyOrders({
    int page = 1,
    int limit = 10,
    String? status,
    String? sortBy,
    String? sortDirection,
  }) async {
    final Map<String, dynamic> body = {
      'pageNo': page,
      'pageSize': limit,
    };

    if (status != null) body['status'] = status;
    if (sortBy != null) body['sortBy'] = sortBy;
    if (sortDirection != null) body['sortDirection'] = sortDirection;

    final response = await _apiService.post<OrderListResponse>(
      ApiConstants.myOrders,
      body: body,
      requiresAuth: true,
      fromJson: (json) => OrderListResponse.fromJson(json),
    );

    return response;
  }

  // Get order by ID
  Future<ApiResponse<Order>> getOrderById(int id) async {
    return await _apiService.get<Order>(
      ApiConstants.orderById(id),
      requiresAuth: true,
      fromJson: (json) => Order.fromJson(json),
    );
  }

  // Check payment status manually
  Future<ApiResponse<Order>> checkPaymentStatus(int id) async {
    return await _apiService.post<Order>(
      ApiConstants.checkPayment(id),
      body: {}, // empty body
      requiresAuth: true,
      fromJson: (json) => Order.fromJson(json['order']),
    );
  }

  // Get PayWay payload for existing order
  Future<ApiResponse<Map<String, dynamic>>> getPaywayPayload(int id, String paymentOption) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.paywayPayload(id),
      body: {'paymentOption': paymentOption},
      requiresAuth: true,
      fromJson: (json) => json,
    );
  }
}
