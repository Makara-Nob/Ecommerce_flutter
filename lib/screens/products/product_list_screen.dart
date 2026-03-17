import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/product_provider.dart';
import '../../providers/home_provider.dart';
import '../../models/home/promotion_model.dart';
import '../../models/product/product.dart';
import '../../services/product_service.dart';
import '../../models/product/product_list_response.dart';
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
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────────────
          GradientBackground(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
                child: Row(
                  children: [
                    if (!_isSearching) ...[
                      const Icon(Icons.storefront_outlined, color: Colors.white, size: 26),
                      const SizedBox(width: 10),
                      const Text(
                        'Shop',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _startSearch,
                        icon: const Icon(Icons.search, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllProductsScreen())),
                        icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
                        tooltip: 'All Products',
                      ),
                    ] else ...[
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ],
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
                        return SizedBox(
                          height: 180,
                          child: PageView.builder(
                            itemCount: homeProvider.banners.length,
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
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
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
                              height: 100,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemCount: homeProvider.categories.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final cat = homeProvider.categories[index];
                                  return _IconicItem(
                                    title: cat.name,
                                    imageUrl: cat.icon,
                                    fallbackIcon: Icons.category_rounded,
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
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (onShowMore != null)
            TextButton(
              onPressed: onShowMore,
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryStart),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Show More', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 13),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Iconic Item Widget (For Categories & Brands) ────────────────────────────
class _IconicItem extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final IconData fallbackIcon;
  final VoidCallback onTap;
  final int index;

  const _IconicItem({
    required this.title,
    this.imageUrl,
    required this.fallbackIcon,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey[100]!, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(fallbackIcon, color: AppColors.primaryStart, size: 26),
                    )
                  : Icon(fallbackIcon, color: AppColors.primaryStart, size: 26),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.1);
  }
}
