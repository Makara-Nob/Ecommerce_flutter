import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product/product.dart';
import '../theme/app_colors.dart';
import '../providers/home_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../screens/auth/login_screen.dart';
import '../models/home/promotion_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final String? discountBadge;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.discountBadge,
  });

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Generate a gradient based on product ID for visual variety
  LinearGradient _getProductGradient() {
    final gradients = [
      const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)]),
      const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A3A0)]),
      const LinearGradient(colors: [Color(0xFFF7B731), Color(0xFFFA8231)]),
      const LinearGradient(colors: [Color(0xFF5F27CD), Color(0xFF341F97)]),
      const LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)]),
      const LinearGradient(colors: [Color(0xFFFD79A8), Color(0xFFE84393)]),
    ];
    return gradients[product.id % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeProvider = Provider.of<HomeProvider>(context);
    final activePromotion = homeProvider.promotions.cast<PromotionModel?>().firstWhere(
      (p) => p?.productId == product.id.toString(),
      orElse: () => null,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with gradient placeholder
              Expanded(
                flex: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Product image
                    if (product.images.isNotEmpty || product.imageUrl != null)
                      Image.network(
                        product.images.isNotEmpty
                            ? product.images.first
                            : product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              decoration: BoxDecoration(
                                gradient: _getProductGradient(),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 40,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: _getProductGradient(),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 40,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    // Glassy Brand badge (top-left)
                    if (product.brand != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.brand!.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),

                    // Modern Discount badge (top-right)
                    if (discountBadge != null || activePromotion != null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: activePromotion != null ? const LinearGradient(
                              colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
                            ) : null,
                            color: activePromotion == null ? AppColors.errorLight : null,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                            ]
                          ),
                          child: Text(
                            activePromotion != null
                                ? (activePromotion.discountType == 'PERCENTAGE'
                                    ? '${activePromotion.discountValue.toInt()}% OFF'
                                    : '${_formatCurrency(activePromotion.discountValue)} OFF')
                                : discountBadge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),

                      // Wishlist Heart Icon (bottom-right of image)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Consumer<WishlistProvider>(
                          builder: (context, wishlist, _) {
                            final isFavorite = wishlist.isExist(product.id);
                            return GestureDetector(
                              onTap: () {
                                final auth = Provider.of<AuthProvider>(context, listen: false);
                                if (!auth.isAuthenticated) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                                } else {
                                  wishlist.toggleWishlist(product);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.grey,
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product Name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1.2,
                          color: AppColors.textPrimaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Category & Price Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (product.category != null)
                            Expanded(
                              child: Text(
                                product.category!.name.toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.textTertiaryLight,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          // Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (activePromotion != null || product.sellingPrice < product.costPrice)
                                Text(
                                  _formatCurrency(product.sellingPrice < product.costPrice ? product.costPrice : product.sellingPrice),
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey[400],
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                activePromotion != null 
                                  ? _formatCurrency(activePromotion.discountType == 'PERCENTAGE' 
                                      ? product.sellingPrice * (1 - (activePromotion.discountValue / 100))
                                      : (product.sellingPrice - activePromotion.discountValue).clamp(0.0, double.infinity))
                                  : _formatCurrency(product.sellingPrice),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: activePromotion != null ? AppColors.accentPink : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
      )
      .animate()
      .fadeIn(duration: 300.ms)
      .scale(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1, 1),
        duration: 300.ms,
      );
  }
}
