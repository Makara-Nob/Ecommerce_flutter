class ApiConstants {
  // Base URL - Change this to your computer's IP address for physical device testing
  // For Android Emulator use: http://10.0.2.2:8888
  // For physical device use: http://YOUR_IP:8888 (e.g., http://192.168.1.100:8888)
  // static const String baseUrl = 'https://ecommerce-backend-v8k1.onrender.com';
  static const String baseUrl = 'http://10.0.2.2:5000';

  //api request time config
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 90);

  // API Endpoints
  
  // Auth endpoints
  static const String login = '/api/v1/auth/login';
  static const String register = '/api/v1/auth/register';
  static const String verifyOtp = '/api/v1/auth/verify-otp';
  static const String resendOtp = '/api/v1/auth/resend-otp';
  static const String validateToken = '/api/v1/auth/validate-token';
  static const String getProfile = '/api/v1/auth/me';
  static const String updateProfile = '/api/v1/auth/token/update-profile';
  
  // Public Product endpoints (no auth required)
  static const String publicProducts = '/api/v1/public/products/all';
  static String publicProductById(int id) => '/api/v1/public/products/$id';
  static String relatedProducts(int id) => '/api/v1/public/products/$id/related';
  static String popularProducts({int page = 1, int limit = 10}) =>
      '/api/v1/public/products/popular?page=$page&limit=$limit';
  static String latestProducts({int page = 1, int limit = 10}) =>
      '/api/v1/public/products/latest?page=$page&limit=$limit';
  
  // Cart endpoints (auth required)
  static const String cart = '/api/v1/cart';
  static const String cartItems = '/api/v1/cart/items';
  static String cartItem(int itemId) => '/api/v1/cart/items/$itemId';
  
  // Order endpoints (auth required)
  static const String orders = '/api/v1/orders';
  static const String myOrders = '/api/v1/orders/my-orders';
  static const String linkCard = '/api/v1/orders/link-card';
  static String orderById(int id) => '/api/v1/orders/$id';
  static String checkPayment(int id) => '/api/v1/orders/$id/check-payment';
  static String paywayPayload(int id) => '/api/v1/orders/$id/payway-payload';
  static String payByToken(int id) => '/api/v1/orders/$id/pay-by-token';

  // Saved cards endpoints
  static const String savedCards = '/api/v1/users/saved-cards';
  static String deleteCard(int index) => '/api/v1/users/saved-cards/$index';

  // Notification endpoints (auth required)
  static const String notifications = '/api/v1/notifications';
  static const String markAllNotificationsRead = '/api/v1/notifications/read-all';
  static String markNotificationRead(String id) => '/api/v1/notifications/$id/read';

  
  // Banner endpoints (public)
  static const String publicBanners = '/api/v1/public/banners';
  
  // Category endpoints (public)
  static const String publicCategories = '/api/v1/public/categories';
  
  // Brand endpoints (public)
  static const String publicBrands = '/api/v1/public/brands';
  
  // Headers
  static const String contentTypeJson = 'application/json';
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
  
  // Storage keys
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';
}
