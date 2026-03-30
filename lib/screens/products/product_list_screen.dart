import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/product_provider.dart';
import '../../providers/home_provider.dart';
import '../../models/home/promotion_model.dart';
import '../../models/product/product.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/gradient_background.dart';
import '../../theme/app_colors.dart';
import 'product_detail_screen.dart';
import 'all_products_screen.dart';
import 'popular_products_screen.dart';
import 'new_arrivals_screen.dart';
import 'promotion_list_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'all_categories_screen.dart';
import '../profile/wishlist_screen.dart';
import '../notifications/notification_screen.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../cart/cart_screen.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/glass_container.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  // State for home sections
  List<Product> _popularProducts = [];
  List<Product> _latestProducts = [];
  bool _isSectionsLoading = true;
  final _productService = ProductService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<HomeProvider>(context, listen: false).fetchHomeData();
      await _loadSections();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSections() async {
    if (!mounted) return;
    setState(() => _isSectionsLoading = true);
    try {
      final results = await Future.wait([
        _productService.getPopularProducts(page: 1, limit: 10),
        _productService.getLatestProducts(page: 1, limit: 10),
      ]);
      if (!mounted) return;
      setState(() {
        _isSectionsLoading = false;
        final popularRes = results[0];
        final latestRes = results[1];
        if (popularRes.success && popularRes.data != null) _popularProducts = popularRes.data!.products;
        if (latestRes.success && latestRes.data != null) _latestProducts = latestRes.data!.products;
      });
    } catch (e) {
      if (mounted) setState(() => _isSectionsLoading = false);
      debugPrint('Error loading home sections: $e');
    }
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  Future<void> _launchURL(String url) async {
    if (url.startsWith('/products/')) {
      final parts = url.split('/');
      if (parts.length >= 3) {
        final productId = int.tryParse(parts[2]);
        if (productId != null) {
          final res = await _productService.getProductById(productId);
          if (res.success && res.data != null && mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: res.data!)));
            return;
          }
        }
      }
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) launchUrl(uri);
  }

  String _formatDiscount(PromotionModel promo) {
    if (promo.discountType.toUpperCase() == 'PERCENTAGE') {
      return '-${promo.discountValue.toStringAsFixed(0)}%';
    } else {
      return '-\$${promo.discountValue.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GlassContainer(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(vertical: 2),
              blur: 15,
              opacity: 0.08,
              borderRadius: BorderRadius.circular(30),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      if (!_isSearching) ...[
                        // Compact logo icon
                          BrandLogo(isCompact: true, showTitle: false, isLight: false)
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            if (!auth.isAuthenticated) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const WishlistScreen()),
                              );
                            }
                          },
                          icon: const Icon(Icons.favorite_border, color: AppColors.textPrimaryLight),
                        ),
                        Consumer<NotificationProvider>(
                          builder: (context, notificationProvider, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const NotificationScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.notifications_none, color: AppColors.textPrimaryLight),
                                ),
                                if (notificationProvider.unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        notificationProvider.unreadCount > 9 ? '9+' : '${notificationProvider.unreadCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        IconButton(
                          onPressed: _startSearch,
                          icon: const Icon(Icons.search, color: AppColors.textPrimaryLight),
                        ),
                      ] else ...[
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: const TextStyle(color: Colors.black87),
                              decoration: const InputDecoration(
                                hintText: 'Search products...',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.search, color: Colors.grey),
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                              onSubmitted: (value) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AllProductsScreen(initialSearch: value),
                                  ),
                                );
                                _stopSearch();
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _stopSearch,
                          icon: const Icon(Icons.close, color: AppColors.textPrimaryLight),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // ── Scrollable Body ───────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryStart,
              onRefresh: () async {
                await Future.wait([
                  Provider.of<HomeProvider>(context, listen: false).fetchHomeData(),
                  _loadSections(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Banners ─────────────────────────────────────────
                    Consumer<HomeProvider>(
                      builder: (context, homeProvider, _) {
                        if (homeProvider.banners.isEmpty) return const SizedBox.shrink();
                        final bannerHeight = MediaQuery.of(context).size.height * 0.5;
                        int currentBanner = 0;
                        return StatefulBuilder(
                          builder: (context, setInnerState) {
                            return Column(
                              children: [
                                SizedBox(
                                  height: bannerHeight - 40,
                                  child: PageView.builder(
                                    itemCount: homeProvider.banners.length,
                                    onPageChanged: (index) => setInnerState(() => currentBanner = index),
                                    itemBuilder: (context, index) {
                                      final banner = homeProvider.banners[index];
                                      return GestureDetector(
                                        onTap: () {
                                          if (banner.linkUrl != null && banner.linkUrl!.isNotEmpty) {
                                            _launchURL(banner.linkUrl!);
                                          }
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(24),
                                            child: Image.network(
                                              banner.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.broken_image, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Modern Dot Indicator
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: homeProvider.banners.asMap().entries.map((entry) {
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: currentBanner == entry.key ? 24 : 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        gradient: currentBanner == entry.key 
                                          ? AppColors.primaryGradient 
                                          : null,
                                        color: currentBanner == entry.key 
                                          ? null 
                                          : Colors.grey[300],
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                        );
                      },
                    ),

                    // ── 2. Categories ──────────────────────────────────────
                    Consumer<HomeProvider>(
                      builder: (context, homeProvider, _) {
                        if (homeProvider.isLoading && homeProvider.categories.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: SizedBox(height: 4, child: LinearProgressIndicator())),
                          );
                        }
                        if (homeProvider.categories.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(
                              title: 'Categories',
                              onShowMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllCategoriesScreen())),
                            ),
                            SizedBox(
                              height: 170,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemCount: homeProvider.categories.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final cat = homeProvider.categories[index];
                                  return _LargeCategoryCard(
                                    title: cat.name,
                                    imageUrl: cat.icon,
                                    onTap: () {
                                      final provider = Provider.of<ProductProvider>(context, listen: false);
                                      provider.filterByCategory(cat.id);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AllProductsScreen(
                                            initialCategoryId: cat.id,
                                            title: cat.name,
                                          ),
                                        ),
                                      );
                                    },
                                    index: index,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),

                    // ── 4. Promotions ──────────────────────────────────────
                    Consumer<HomeProvider>(
                      builder: (context, homeProvider, _) {
                        if (homeProvider.promotions.isEmpty) return const SizedBox.shrink();
                        final promos = homeProvider.promotions.take(10).toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(
                              title: 'Special Offers 🔥',
                              onShowMore: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PromotionListScreen()),
                              ),
                            ),
                            SizedBox(
                              height: 230,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemCount: promos.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final promo = promos[index];
                                  return SizedBox(
                                    width: 150,
                                    child: ProductCard(
                                      product: promo.product,
                                      discountBadge: _formatDiscount(promo),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: promo.product)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),

                    // ── 4. Popular Products ────────────────────────────────
                    _SectionHeader(
                      title: 'Popular 📈',
                      onShowMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PopularProductsScreen())),
                    ),
                    _isSectionsLoading
                        ? SizedBox(
                            height: 230,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: 4,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (_, __) => const SizedBox(width: 150, child: ProductCardShimmer()),
                            ),
                          )
                        : SizedBox(
                            height: 230,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: _popularProducts.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final product = _popularProducts[index];
                                return SizedBox(
                                  width: 150,
                                  child: ProductCard(
                                    product: product,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: (index * 50).ms);
                              },
                            ),
                          ),

                    const SizedBox(height: 8),

                    // ── 5. New Arrivals ────────────────────────────────────
                    _SectionHeader(
                      title: 'New Arrivals 🆕',
                      onShowMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewArrivalsScreen())),
                    ),
                    _isSectionsLoading
                        ? SizedBox(
                            height: 230,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: 4,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (_, __) => const SizedBox(width: 150, child: ProductCardShimmer()),
                            ),
                          )
                        : SizedBox(
                            height: 230,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: _latestProducts.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final product = _latestProducts[index];
                                return SizedBox(
                                  width: 150,
                                  child: ProductCard(
                                    product: product,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: (index * 50).ms);
                              },
                            ),
                          ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Section Header ─────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onShowMore;

  const _SectionHeader({required this.title, this.onShowMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          if (onShowMore != null)
            TextButton(
              onPressed: onShowMore,
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryEnd),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Immersive Large Category Card Widget ──────────────────────────────────────────────
class _LargeCategoryCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback onTap;
  final int index;

  const _LargeCategoryCard({
    required this.title,
    this.imageUrl,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.category, color: AppColors.primaryStart, size: 40),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.category, color: AppColors.primaryStart, size: 40),
                    ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.5, 0.7, 1.0],
                ),
              ),
            ),
            // Title
            Positioned(
              bottom: 16,
              left: 12,
              right: 12,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms).scale(begin: const Offset(0.95, 0.95));
  }
}
