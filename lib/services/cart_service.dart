import '../models/api_response.dart';
import '../models/cart/cart.dart';
import '../models/cart/cart_item.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class CartService {
  final ApiService _apiService = ApiService();

  // Get current user's cart
  Future<ApiResponse<Cart>> getCart() async {
    return await _apiService.get<Cart>(
      ApiConstants.cart,
      requiresAuth: true,
      fromJson: (json) => Cart.fromJson(json),
    );
  }

  // Add item to cart
  Future<ApiResponse<Cart>> addToCart(int productId, int quantity, {int? variantId}) async {
    final request = CartItemRequest(
      productId: productId,
      quantity: quantity,
      variantId: variantId,
    );

    return await _apiService.post<Cart>(
      ApiConstants.cartItems,
      body: request.toJson(),
      requiresAuth: true,
      fromJson: (json) => Cart.fromJson(json),
    );
  }

  // Update item quantity
  Future<ApiResponse<Cart>> updateItemQuantity(int itemId, int quantity) async {
    return await _apiService.put<Cart>(
      ApiConstants.cartItem(itemId),
      body: {'quantity': quantity},
      requiresAuth: true,
      fromJson: (json) => Cart.fromJson(json),
    );
  }

  // Remove item from cart
  Future<ApiResponse<Cart>> removeItem(int itemId) async {
    return await _apiService.delete<Cart>(
      ApiConstants.cartItem(itemId),
      requiresAuth: true,
      fromJson: (json) => Cart.fromJson(json),
    );
  }

  // Clear cart
  Future<ApiResponse<String>> clearCart() async {
    return await _apiService.delete<String>(
      ApiConstants.cart,
      requiresAuth: true,
      fromJson: (json) => json?.toString() ?? 'Cart cleared',
    );
  }
}
