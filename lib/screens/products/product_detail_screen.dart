import 'package:e_commerce/constants/api_constants.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../../models/product/product.dart';
import '../../models/product/product_variant.dart';
import '../../providers/cart_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/review/review.dart';
import '../../services/review_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../cart/cart_screen.dart';
import '../../widgets/product_card.dart';
import '../../services/product_service.dart';
import '../../models/api_response.dart';
import '../../models/home/brand_model.dart';
import 'brand_detail_screen.dart';
import '../../providers/home_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../models/home/promotion_model.dart';
import '../../models/cart/cart_item.dart';
import '../orders/checkout_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens for the new "clean" style
// ─────────────────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF2B60E6);
const _kPrimaryLight = Color(0xFFEEF2FF);
const _kStarColor = Color(0xFFFFA726);
const _kDivider = Color(0xFFEEEEEE);
const _kSubText = Color(0xFF8E8E93);

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final int? initialVariantId;

  const ProductDetailScreen(
      {super.key, required this.product, this.initialVariantId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  ProductVariant? _selectedVariant;
  Map<String, String> _selectedOptions = {};
  int _currentImageIndex = 0;
  int _currentThumbIndex = 0;
  late final PageController _pageController = PageController();
  Timer? _autoPlayTimer;
  late Future<ApiResponse<List<Product>>> _relatedProductsFuture;

  List<String> get _displayImages {
    final variantImg = _selectedVariant?.imageUrl;
    final base = widget.product.images.isNotEmpty
        ? widget.product.images
        : (widget.product.imageUrl != null
            ? [widget.product.imageUrl!]
            : <String>[]);
    if (variantImg != null && !base.contains(variantImg)) {
      return [variantImg, ...base];
    }
    return base.isNotEmpty ? base : (variantImg != null ? [variantImg] : []);
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_displayImages.length <= 1) return;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentImageIndex + 1) % _displayImages.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _resolveSelectedVariant() {
    if (_selectedOptions.length != widget.product.options.length) {
      _selectedVariant = null;
      return;
    }
    final selectedValues = widget.product.options
        .map((o) => _selectedOptions[o.name]!.trim().toLowerCase())
        .toList();
    try {
      _selectedVariant = widget.product.variants.firstWhere((v) {
        if (v.optionValues.length != selectedValues.length) return false;
        for (int i = 0; i < selectedValues.length; i++) {
          if (v.optionValues[i].trim().toLowerCase() != selectedValues[i]) return false;
        }
        return true;
      });
    } catch (e) {
      _selectedVariant = null;
    }
  }

  // ── Review State ──────────────────────────────────────────────────────────
  final ReviewService _reviewService = ReviewService();
  final List<XFile> _selectedReviewImages = [];
  ReviewSummary _reviewSummary = ReviewSummary.empty();
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;
  int _reviewsPage = 1;
  bool _hasMoreReviews = true;
  Review? _myReview;

  Future<void> _fetchReviews({bool loadMore = false}) async {
    if (_isLoadingReviews || (!loadMore && !_hasMoreReviews && _reviews.isNotEmpty)) return;
    
    setState(() => _isLoadingReviews = true);
    try {
      final nextPage = loadMore ? _reviewsPage + 1 : 1;
      const limit = 3; // Show 3 at a time as requested

      final result = await _reviewService.getProductReviews(
        widget.product.id,
        page: nextPage,
        limit: limit,
      );
      
      setState(() {
        if (loadMore) {
          _reviews.addAll(result['reviews'] as List<Review>);
          _reviewsPage = nextPage;
        } else {
          _reviews = result['reviews'] as List<Review>;
          _reviewsPage = 1;
        }
        _reviewSummary = result['summary'] as ReviewSummary;
        // Total pages calculated by backend based on limit
        _hasMoreReviews = _reviewsPage < (result['totalPages'] as int);
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => _isLoadingReviews = false);
      debugPrint('Error fetching reviews: $e');
    }
  }

  Future<void> _checkMyReview() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;
    try {
      final r = await _reviewService.getMyReview(widget.product.id, auth.token!);
      setState(() => _myReview = r);
    } catch (e) {
      debugPrint('Error checking my review: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchReviews();
    _checkMyReview();
    _relatedProductsFuture =
        ProductService().getRelatedProducts(widget.product.id);
    if (widget.initialVariantId != null) {
      try {
        _selectedVariant = widget.product.variants
            .firstWhere((v) => v.id == widget.initialVariantId);
        for (int i = 0; i < widget.product.options.length; i++) {
          if (i < _selectedVariant!.optionValues.length) {
            _selectedOptions[widget.product.options[i].name] =
                _selectedVariant!.optionValues[i];
          }
        }
      } catch (e) {
        // ignore
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay());
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String get _variantSectionLabel {
    if (widget.product.options.isEmpty) return 'Choose an Option';
    return widget.product.options.map((o) => o.name).join(' & ');
  }

  Color? _parseColor(String raw) {
    final name = raw.toLowerCase().trim();
    const map = {
      'black': Color(0xFF212121),
      'white': Color(0xFFF5F5F5),
      'red': Color(0xFFE53935),
      'pink': Color(0xFFE91E63),
      'purple': Color(0xFF9C27B0),
      'blue': Color(0xFF1E88E5),
      'cyan': Color(0xFF00BCD4),
      'teal': Color(0xFF00897B),
      'green': Color(0xFF43A047),
      'lime': Color(0xFFCDDC39),
      'yellow': Color(0xFFFDD835),
      'amber': Color(0xFFFFB300),
      'orange': Color(0xFFFB8C00),
      'brown': Color(0xFF6D4C41),
      'grey': Color(0xFF9E9E9E),
      'gray': Color(0xFF9E9E9E),
      'silver': Color(0xFFBDBDBD),
      'gold': Color(0xFFD4AF37),
      'navy': Color(0xFF1A237E),
      'beige': Color(0xFFF5F0DC),
      'midnight': Color(0xFF263238),
      'desert titanium': Color(0xFFB5A58C),
      'natural titanium': Color(0xFFB0AFAD),
      'white titanium': Color(0xFFE8E8E8),
      'black titanium': Color(0xFF3C3C3C),
    };
    if (map.containsKey(name)) return map[name];
    final hex = name.replaceFirst('#', '');
    if (hex.length == 6) {
      final val = int.tryParse('FF$hex', radix: 16);
      if (val != null) return Color(val);
    }
    return null;
  }

  // ─── Share ───────────────────────────────────────────────────────────────
  void _handleShare(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    double price = widget.product.sellingPrice;
    if (_selectedVariant != null && _selectedVariant!.additionalPrice > 0) {
      price += _selectedVariant!.additionalPrice;
    }

    final rawDesc = widget.product.description ?? '';
    final descSnippet = rawDesc.replaceAll(RegExp(r'[\n•]'), ' ').trim();
    final shortDesc = descSnippet.length > 120
        ? '${descSnippet.substring(0, 120).trimRight()}…'
        : descSnippet;

    final variantLine = _selectedVariant?.variantName != null
        ? '\nVariant: ${_selectedVariant!.variantName}'
        : '';

    final brandLine = widget.product.brand != null
        ? '\nBrand: ${widget.product.brand!.name}'
        : '';

    final shareText = '''
🛍️ Check out this product!

${widget.product.name}$variantLine$brandLine
💰 Price: ${formatter.format(price)}

$shortDesc

— Shared from NAGA''';

    Share.share(shareText.trim()); // ← this is all that changed
  }

  // ─── build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeProvider = Provider.of<HomeProvider>(context);
    final activePromotion =
        homeProvider.promotions.cast<PromotionModel?>().firstWhere(
              (p) => p?.productId == widget.product.id.toString(),
              orElse: () => null,
            );

    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    // Price computation
    double baseAmount = widget.product.sellingPrice;
    if (_selectedVariant != null && _selectedVariant!.additionalPrice > 0) {
      baseAmount += _selectedVariant!.additionalPrice;
    }
    double finalAmount = baseAmount;
    if (activePromotion != null) {
      if (activePromotion.discountType == 'PERCENTAGE') {
        finalAmount = baseAmount * (1 - (activePromotion.discountValue / 100));
      } else {
        finalAmount = (baseAmount - activePromotion.discountValue)
            .clamp(0.0, double.infinity);
      }
    }

    final bool hasDiscount =
        activePromotion != null || finalAmount < baseAmount;
    final bool inStock = widget.product.quantity > 0 ||
        (widget.product.variants.isNotEmpty &&
            widget.product.variants.any((v) => v.stockQuantity > 0));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image Hero ──────────────────────────────────────────────────
            _buildImageHero(),

            // ── Content ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                      height: 1.3,
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 50.ms),

                  const SizedBox(height: 8),

                  // Brand + rating row
                  _buildMetaRow(context),

                  const SizedBox(height: 16),

                  // Price + Quantity inline
                  _buildPriceQuantityRow(
                      formatter, finalAmount, baseAmount, hasDiscount),

                  // Promo badge
                  if (activePromotion != null) ...[
                    const SizedBox(height: 12),
                    _buildPromoBadge(formatter, activePromotion),
                  ],

                  // ── Options/Variants ──────────────────────────────────────
                  if (widget.product.variants.isNotEmpty &&
                      widget.product.options.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildOptionsSection(context),
                  ],

                  // ── Description ───────────────────────────────────────────
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildDescriptionSection(context),
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildReviewsSection(context),
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildRelatedProducts(context),

                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),
      ),
      // ── Bottom Action Bar ─────────────────────────────────────────────────
      bottomSheet: inStock ? _buildBottomBar(context, activePromotion, finalAmount) : null,
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: Color(0xFF1A1A2E)),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        Consumer<WishlistProvider>(
          builder: (context, wishlist, _) {
            final isFav = wishlist.isExist(widget.product.id);
            return IconButton(
              icon: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isFav
                      ? const Color(0xFFFFEEEE)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 18,
                  color: isFav ? Colors.red : const Color(0xFF1A1A2E),
                ),
              ),
              onPressed: () {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                if (!auth.isAuthenticated) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                } else {
                  wishlist.toggleWishlist(widget.product);
                }
              },
            );
          },
        ),
        IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.share_rounded,
                size: 18, color: Color(0xFF1A1A2E)),
          ),
          onPressed: () => _handleShare(context),
        ),
        IconButton(
          icon: Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              final count = cartProvider.itemCount;
              return Badge(              // ← outside container, no clipping
                label: Text('$count'),
                isLabelVisible: count > 0,
                backgroundColor: Colors.red,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined,
                      size: 18, color: Color(0xFF1A1A2E)),
                ),
              );
            },
          ),
          onPressed: () {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (!auth.isAuthenticated) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ─── Image Hero ───────────────────────────────────────────────────────────
  Widget _buildImageHero() {
    final images = _displayImages;
    return Column(
      children: [
        // Main image
        Container(
          height: 280,
          width: double.infinity,
          color: const Color(0xFFF8F9FF),
          child: images.isEmpty
              ? Center(
                  child: Icon(Icons.shopping_bag_outlined,
                      size: 80, color: Colors.grey[300]),
                )
              : PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (i) =>
                      setState(() => _currentImageIndex = i),
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Image.network(
                      images[i],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.shopping_bag_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ),
        ),

        // Thumbnail row
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final isActive = i == _currentImageIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                    setState(() {
                      _currentImageIndex = i;
                      _currentThumbIndex = i;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? _kPrimary : _kDivider,
                        width: isActive ? 2 : 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.network(
                      images[i],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.image_outlined, color: Colors.grey[400]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ─── Meta Row (Brand, Rating) ─────────────────────────────────────────────
  Widget _buildMetaRow(BuildContext context) {
    return Row(
      children: [
        if (widget.product.brand != null) ...[
          GestureDetector(
            onTap: () {
              final b = widget.product.brand!;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BrandDetailScreen(
                    brand: BrandModel(
                      id: b.id,
                      name: b.name,
                      description: b.description,
                      logo: b.logoUrl,
                    ),
                  ),
                ),
              );
            },
            child: Text(
              'By ${widget.product.brand!.name}',
              style: const TextStyle(
                fontSize: 13,
                color: _kPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _dot(),
        ],
        // Star row
        const Icon(Icons.star_rounded, color: _kStarColor, size: 15),
        const SizedBox(width: 3),
        Text(
          _reviewSummary.avgRating > 0 ? _reviewSummary.avgRating.toString() : '0.0',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        Text(
          ' (${_reviewSummary.totalCount})',
          style: const TextStyle(fontSize: 12, color: _kSubText),
        ),
        const Icon(Icons.chevron_right_rounded, color: _kSubText, size: 16),
        const Spacer(),
        if (widget.product.category != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kPrimaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.product.category!.name,
              style: const TextStyle(
                  fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  // ─── Price + Quantity Row ─────────────────────────────────────────────────
  Widget _buildPriceQuantityRow(
      NumberFormat formatter, double final_, double base, bool hasDiscount) {
    final maxQty = _selectedVariant?.stockQuantity ?? widget.product.quantity;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Price block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatter.format(final_),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                  height: 1,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(height: 3),
                Text(
                  formatter.format(base),
                  style: const TextStyle(
                    fontSize: 14,
                    color: _kSubText,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Quantity selector
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyBtn(
                icon: Icons.remove_rounded,
                enabled: _quantity > 1,
                onTap: () => setState(() => _quantity--),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              _qtyBtn(
                icon: Icons.add_rounded,
                enabled: _quantity < maxQty,
                onTap: () => setState(() => _quantity++),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qtyBtn(
      {required IconData icon,
      required bool enabled,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? _kPrimary : const Color(0xFFDDDDDD),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  // ─── Promo Badge ──────────────────────────────────────────────────────────
  Widget _buildPromoBadge(
      NumberFormat formatter, PromotionModel promo) {
    final label = promo.discountType == 'PERCENTAGE'
        ? '${promo.discountValue.toInt()}% OFF'
        : '${formatter.format(promo.discountValue)} OFF';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3D57).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFFF3D57).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer_rounded,
              color: Color(0xFFFF3D57), size: 14),
          const SizedBox(width: 6),
          Text(
            '$label  ·  Valid ${DateFormat('MMM d').format(promo.startDate)} – ${DateFormat('MMM d, yyyy').format(promo.endDate)}',
            style: const TextStyle(
              color: Color(0xFFFF3D57),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Options/Variants Section ─────────────────────────────────────────────
  Widget _buildOptionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.product.options.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // e.g. "Color" or "Storage"
              Row(
                children: [
                  Text(
                    option.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  if (_selectedOptions.containsKey(option.name)) ...[
                    const SizedBox(width: 8),
                    Text(
                      _selectedOptions[option.name]!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: _kPrimary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                  const Spacer(),
                  if (!_selectedOptions.containsKey(option.name))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Required',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF856404),
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: option.values.map((val) {
                  final isSelected = _selectedOptions[option.name] == val;
                  final isColor = option.name.toLowerCase() == 'color';
                  final parsedColor = isColor ? _parseColor(val) : null;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedOptions.remove(option.name);
                        } else {
                          _selectedOptions[option.name] = val;
                        }
                        _resolveSelectedVariant();
                        _currentImageIndex = 0;
                        _pageController.jumpToPage(0);
                        _startAutoPlay();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected ? _kPrimaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? _kPrimary : _kDivider,
                          width: isSelected ? 1.8 : 1.3,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (parsedColor != null) ...[
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: parsedColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? _kPrimary.withOpacity(0.3)
                                      : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                          ],
                          Text(
                            val,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? _kPrimary
                                  : const Color(0xFF444444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Description ─────────────────────────────────────────────────────────
  // Detects whether the description is bullet-point style (lines with •)
  // or plain prose and renders accordingly.
  Widget _buildDescriptionSection(BuildContext context) {
    final desc = widget.product.description ?? 'No description available.';

    // --- Bullet detection: split by newline, check if any line starts with •
    final rawLines = desc.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final isBulletList = rawLines.any((l) => l.startsWith('•'));

    if (isBulletList) {
      // Collect only the bullet lines, strip the leading •
      final bullets = rawLines
          .where((l) => l.startsWith('•'))
          .map((l) => l.substring(1).trim())
          .where((l) => l.isNotEmpty)
          .toList();

      // Optional intro line (any non-bullet line before the bullets)
      final introLines = rawLines
          .takeWhile((l) => !l.startsWith('•'))
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A Snapshot View',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E)),
          ),
          if (introLines.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              introLines.join(' '),
              style: const TextStyle(
                  fontSize: 13, color: _kSubText, height: 1.5),
            ),
          ],
          const SizedBox(height: 14),
          ...bullets.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _kPrimaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 15, color: _kPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          line,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF444444),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      );
    } else {
      // Plain prose — just render a readable paragraph
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: const TextStyle(
                fontSize: 14, color: _kSubText, height: 1.65),
          ),
        ],
      );
    }
  }

  // ─── Related Products ─────────────────────────────────────────────────────
  Widget _buildRelatedProducts(BuildContext context) {
    return FutureBuilder<ApiResponse<List<Product>>>(
      future: _relatedProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final products = snapshot.data?.data;
        if (products == null || products.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Related Products',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (ctx, i) => SizedBox(
                  width: 155,
                  child: ProductCard(
                    product: products[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailScreen(product: products[i]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────────
  Widget _buildBottomBar(
      BuildContext context, PromotionModel? activePromotion, double finalAmount) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kDivider, width: 1)),
      ),
      child: Row(
        children: [
          // Buy Now
          Expanded(
            child: OutlinedButton(
              onPressed: () => _handleBuyNow(context, activePromotion, finalAmount),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: _kPrimary, width: 1.8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                foregroundColor: _kPrimary,
              ),
              child: const Text('Buy Now',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          // Add to Cart
          Expanded(
            flex: 2,
            child: Consumer<CartProvider>(
              builder: (context, cartProvider, _) => FilledButton.icon(
                onPressed: cartProvider.isLoading
                    ? null
                    : () => _handleAddToCart(context, cartProvider),
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: cartProvider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.shopping_cart_outlined, size: 18),
                label: const Text('Add to Cart',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────
  void _handleBuyNow(BuildContext context, PromotionModel? activePromotion,
      double finalAmount) {
    if (widget.product.options.isNotEmpty &&
        widget.product.variants.isNotEmpty &&
        _selectedOptions.length < widget.product.options.length) {
      _showVariantSnack(context);
      return;
    }
    final authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      _showLoginPrompt(context, 'Please login to checkout');
      return;
    }
    double price = finalAmount;
    if (_selectedVariant != null) price += _selectedVariant!.additionalPrice;
    final directItem = CartItem(
      id: 0,
      product: widget.product,
      quantity: _quantity,
      price: price,
      subtotal: price * _quantity,
      variantId: _selectedVariant?.id,
      variantName: _selectedVariant?.variantName,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => CheckoutScreen(directItems: [directItem])),
    );
  }

  Future<void> _handleAddToCart(
      BuildContext context, CartProvider cartProvider) async {
    if (widget.product.options.isNotEmpty &&
        widget.product.variants.isNotEmpty &&
        _selectedOptions.length < widget.product.options.length) {
      _showVariantSnack(context);
      return;
    }
    final authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      _showLoginPrompt(context, 'Please login to add items to cart');
      return;
    }
    final success = await cartProvider.addToCart(
      widget.product.id,
      _quantity,
      variantId: _selectedVariant?.id,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            success ? 'Added to cart ✓' : cartProvider.errorMessage ?? 'Failed'),
        backgroundColor: success ? const Color(0xFF27AE60) : AppColors.errorLight,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showVariantSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please select a $_variantSectionLabel first'),
        backgroundColor: const Color(0xFFF39C12),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLoginPrompt(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _dot() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text('·', style: TextStyle(color: _kSubText, fontSize: 14)),
      );

  // ─── Reviews Section ──────────────────────────────────────────────────────
  Widget _buildReviewsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Reviews',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
              if (_myReview == null)
                TextButton.icon(
                  onPressed: () => _showReviewDialog(context),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Write Review'),
                  style: TextButton.styleFrom(
                    foregroundColor: _kPrimary,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                )
              else
                const Text('You reviewed this',
                    style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Rating Overview
        if (_reviewSummary.totalCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        _reviewSummary.avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E)),
                      ),
                      _buildStarRating(_reviewSummary.avgRating.round(), size: 16),
                      const SizedBox(height: 4),
                      Text('${_reviewSummary.totalCount} reviews',
                          style: const TextStyle(fontSize: 12, color: _kSubText)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: List.generate(5, (index) {
                        final star = 5 - index;
                        final count = _reviewSummary.ratingBreakdown[star] ?? 0;
                        final percent = _reviewSummary.totalCount > 0 ? count / _reviewSummary.totalCount : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text('$star', style: const TextStyle(fontSize: 11, color: _kSubText)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percent,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: const AlwaysStoppedAnimation(_kStarColor),
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Review List
        if (_isLoadingReviews && _reviews.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
                child: Text('No reviews yet. Be the first to review!',
                    style: TextStyle(color: _kSubText))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: _kDivider),
            ),
            itemBuilder: (context, index) => _buildReviewCard(_reviews[index]),
          ),

        if (_hasMoreReviews)
          Center(
            child: TextButton(
              onPressed: () => _fetchReviews(loadMore: true),
              child: _isLoadingReviews 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Load More Reviews'),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _kPrimaryLight,
                child: Text(review.userName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 14, color: _kPrimary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _buildStarRating(review.rating, size: 12),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, yyyy').format(review.createdAt),
                        style: const TextStyle(fontSize: 11, color: _kSubText),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (review.title != null && review.title!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(review.title!,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
          const SizedBox(height: 8),
          Text(review.body,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4A4A6A), height: 1.5)),
          
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final imgUrl = review.images[i].startsWith('/') 
                      ? '${ApiConstants.baseUrl}${review.images[i]}' 
                      : review.images[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imgUrl, width: 80, height: 80, fit: BoxFit.cover),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRating(int rating, {double size = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: index < rating ? _kStarColor : Colors.grey[300],
          size: size,
        );
      }),
    );
  }

  void _showReviewDialog(BuildContext context) {
    int rating = 5;
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    bool isSubmitting = false;
    _selectedReviewImages.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Rate this product',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Star Selector
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    final isActive = (i + 1) <= rating;
                    return IconButton(
                      icon: Icon(
                        isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isActive ? _kStarColor : Colors.grey[400],
                        size: 42,
                      ),
                      onPressed: () => setModalState(() => rating = i + 1),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: titleController,
                decoration: _inputStyle('Review Title (Optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: _inputStyle('Tell us your experience...'),
              ),
              const SizedBox(height: 20),
              
              // Image Picker UI
              const Text('Add Photos (Max 5)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);
                        if (images.isNotEmpty) {
                          setModalState(() {
                            _selectedReviewImages.addAll(images);
                            if (_selectedReviewImages.length > 5) {
                              _selectedReviewImages.removeRange(5, _selectedReviewImages.length);
                            }
                          });
                        }
                      },
                      child: Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kDivider),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined, color: _kSubText),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ..._selectedReviewImages.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(entry.value.path),
                                  width: 70, height: 70, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2, right: 2,
                              child: GestureDetector(
                                onTap: () => setModalState(() => _selectedReviewImages.removeAt(entry.key)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (bodyController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a comment')));
                      return;
                    }
                    setModalState(() => isSubmitting = true);
                    try {
                      final token = Provider.of<AuthProvider>(context, listen: false).token!;
                      await _reviewService.createReview(
                        productId: widget.product.id,
                        rating: rating,
                        body: bodyController.text,
                        title: titleController.text,
                        imagePaths: _selectedReviewImages.map((e) => e.path).toList(),
                        token: token,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _fetchReviews();
                      _checkMyReview();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!')));
                    } catch (e) {
                      setModalState(() => isSubmitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: isSubmitting 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: _kSubText),
      fillColor: const Color(0xFFF8F9FF),
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildDivider() =>
      const Divider(color: _kDivider, thickness: 1, height: 1);
}
