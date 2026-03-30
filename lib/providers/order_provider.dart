import 'package:flutter/foundation.dart';
import '../models/order/order.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  static const int _pageSize = 10;
  bool _hasMore = true;

  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  // Create order
  Future<bool> createOrder({
    String? deliveryAddress,
    String? deliveryPhone,
    String? notes,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'ABA_PAYWAY',
    bool? isBuyNow,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _orderService.createOrder(
        deliveryAddress: deliveryAddress,
        deliveryPhone: deliveryPhone,
        notes: notes,
        items: items,
        paymentMethod: paymentMethod,
        isBuyNow: isBuyNow,
      );

      if (response.success && response.data != null) {
        _currentOrder = response.data;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to create order: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load orders
  Future<void> loadOrders({bool refresh = false, String? status}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _orders = [];
    }

    if (_orders.isEmpty) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await _orderService.getMyOrders(
        page: _currentPage,
        limit: _pageSize,
        status: status,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        if (refresh) {
          _orders = data.content;
        } else {
          _orders.addAll(data.content);
        }
        _hasMore = !data.last;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to load orders: $e';
    } finally {
      if (_orders.isEmpty || refresh) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // Load more orders (pagination)
  Future<void> loadMoreOrders({String? status}) async {
    if (_isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPage++;
      final response = await _orderService.getMyOrders(
        page: _currentPage,
        limit: _pageSize,
        status: status,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        _orders.addAll(data.content);
        _hasMore = !data.last;
      } else {
        _currentPage--; // Revert page on error
        _errorMessage = response.message;
      }
    } catch (e) {
      _currentPage--;
      _errorMessage = 'Failed to load more orders: $e';
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // Get order by ID
  Future<void> loadOrderById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _orderService.getOrderById(id);

      if (response.success && response.data != null) {
        _currentOrder = response.data;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to load order: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check payment status manually
  Future<bool> checkPaymentStatus(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _orderService.checkPaymentStatus(id);

      if (response.success && response.data != null) {
        // Update current order if it matches
        if (_currentOrder?.id == id) {
          _currentOrder = response.data;
        }
        
        // Update order in list if it exists
        final index = _orders.indexWhere((o) => o.id == id);
        if (index != -1) {
          _orders[index] = response.data!;
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to check payment status: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get PayWay payload
  Future<Map<String, dynamic>?> getPaywayPayload(int id, String paymentOption) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _orderService.getPaywayPayload(id, paymentOption);
      _isLoading = false;
      notifyListeners();

      if (response.success && response.data != null) {
        return response.data;
      } else {
        _errorMessage = response.message;
        return null;
      }
    } catch (e) {
      _errorMessage = 'Failed to get PayWay payload: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
