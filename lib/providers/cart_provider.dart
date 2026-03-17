import 'package:flutter/foundation.dart';
import '../models/cart/cart.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();

  Cart? _cart;
  bool _isLoading = false;
  String? _errorMessage;

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get itemCount => _cart?.itemCount ?? 0;
  double get totalAmount => _cart?.totalAmount ?? 0.0;

  // Load cart
  Future<void> loadCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartService.getCart();

      if (response.success && response.data != null) {
        _cart = response.data;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to load cart: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add item to cart
  Future<bool> addToCart(int productId, int quantity, {int? variantId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartService.addToCart(productId, quantity, variantId: variantId);

      if (response.success && response.data != null) {
        _cart = response.data;
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
      _errorMessage = 'Failed to add to cart: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update item quantity
  Future<bool> updateQuantity(int itemId, int quantity) async {
    if (_cart == null) return false;
    
    // Save previous state for rollback
    final previousCart = _cart;
    
    // Optimistic Update
    try {
      final itemIndex = _cart!.items.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        final existingItem = _cart!.items[itemIndex];
        final previousQuantity = existingItem.quantity;
        
        // Only update if it actually changed
        if (previousQuantity != quantity) {
           _cart!.items[itemIndex] = existingItem.copyWith(quantity: quantity);
           
           // Recalculate totals optimistically
           _cart = _cart!.copyWith(
              totalAmount: _cart!.items.fold<double>(0.0, (sum, item) => sum + (item.price * item.quantity)),
           );
           notifyListeners();
        }
      }
    } catch (e) {
      // Ignore optimistic update errors
    }

    try {
      final response = await _cartService.updateItemQuantity(itemId, quantity);

      if (response.success && response.data != null) {
        _cart = response.data;
        notifyListeners();
        return true;
      } else {
        // Rollback
        _cart = previousCart;
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Rollback
      _cart = previousCart;
      _errorMessage = 'Failed to update quantity: $e';
      notifyListeners();
      return false;
    }
  }

  // Remove item
  Future<bool> removeItem(int itemId) async {
    if (_cart == null) return false;
    
    // Save previous state for rollback
    final previousCart = _cart;
    
    // Optimistic Update
    try {
      final updatedItems = _cart!.items.where((item) => item.id != itemId).toList();
      _cart = _cart!.copyWith(
          items: updatedItems,
          totalAmount: updatedItems.fold<double>(0.0, (sum, item) => sum + (item.price * item.quantity)),
      );
      notifyListeners();
    } catch (e) {
      // Ignore optimistic update errors
    }

    try {
      final response = await _cartService.removeItem(itemId);

      if (response.success && response.data != null) {
        _cart = response.data;
        notifyListeners();
        return true;
      } else {
        // Rollback
        _cart = previousCart;
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Rollback
      _cart = previousCart;
      _errorMessage = 'Failed to remove item: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear cart
  Future<bool> clearCart() async {
    if (_cart == null) return true;
    
    // Save previous state for rollback
    final previousCart = _cart;
    
    // Optimistic Update
    _cart = null;
    notifyListeners();

    try {
      final response = await _cartService.clearCart();

      // If backend was updated to return Cart, use `response.data`.
      // Otherwise `clearCart` just returns success.
      if (response.success) {
        // Backend clear shouldn't have items.
        // We set it to null and let loadCart/etc handle if needed
        return true;
      } else {
        // Rollback
        _cart = previousCart;
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Rollback
      _cart = previousCart;
      _errorMessage = 'Failed to clear cart: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear local cart state (for logout)
  void clearLocalCart() {
    _cart = null;
    _errorMessage = null;
    notifyListeners();
  }
}
