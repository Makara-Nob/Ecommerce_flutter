import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product/product.dart';
import '../theme/app_colors.dart';
import '../providers/home_provider.dart';
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

    return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image with gradient placeholder
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Product image – prefer images array, fallback to imageUrl
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
                                    size: 48,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                        )
                      else
                        // Gradient background (fallback)
                        Container(
                          decoration: BoxDecoration(
                            gradient: _getProductGradient(),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 48,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      // Brand badge (top-left)
                      if (product.brand != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.brand!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      // Discount badge (top-right)
                      if (discountBadge != null || activePromotion != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: activePromotion != null ? const LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                              ) : null,
                              color: activePromotion == null ? AppColors.errorLight : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              activePromotion != null
                                  ? (activePromotion.discountType == 'PERCENTAGE'
                                      ? '${activePromotion.discountValue.toInt()}% OFF'
                                      : '${_formatCurrency(activePromotion.discountValue)} OFF')
                                  : discountBadge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Product details
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Let it take minimum space
                    children: [
                      // Product Name
                      Text(
                        product.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(
                        height: 8,
                      ), // Increased Gap for breathing room
                      // Price and category
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Category
                          if (product.category != null)
                            Expanded(
                              child: Text(
                                product.category!.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
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
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey[500],
                                    fontSize: 10,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: activePromotion != null ? const LinearGradient(
                                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                                  ) : AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  activePromotion != null 
                                    ? _formatCurrency(activePromotion.discountType == 'PERCENTAGE' 
                                        ? product.sellingPrice * (1 - (activePromotion.discountValue / 100))
                                        : (product.sellingPrice - activePromotion.discountValue).clamp(0.0, double.infinity))
                                    : _formatCurrency(product.sellingPrice),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
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
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 300.ms,
        );
  }
}
