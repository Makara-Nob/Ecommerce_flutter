import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../home/home_screen.dart';
import '../orders/checkout_screen.dart';
import '../products/product_detail_screen.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/brand_logo.dart';

class CartScreen extends StatefulWidget {
  final bool showBackButton;
  const CartScreen({super.key, this.showBackButton = true});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ── Glassmorphic Floating Header ───────────────────────────────────
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
                      if (widget.showBackButton) ...[
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryLight, size: 20),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Text(
                        'Shopping Cart',
                        style: TextStyle(
                          color: AppColors.textPrimaryLight,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          if (cartProvider.cart != null &&
                              cartProvider.cart!.items.isNotEmpty) {
                            return IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorLight),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Clear Cart'),
                                    content: const Text('Are you sure you want to remove all items from your cart?'),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: FilledButton.styleFrom(backgroundColor: AppColors.errorLight),
                                        child: const Text('Clear'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true && context.mounted) {
                                  await cartProvider.clearCart();
                                }
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn().slideY(begin: -0.1),
          
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                if (cartProvider.isLoading && cartProvider.cart == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (cartProvider.cart == null ||
                    cartProvider.cart!.items.isEmpty) {
                  return EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Your cart is empty',
                    description: 'Looks like you haven\'t added anything to your cart yet'
                  );
                }

                final cart = cartProvider.cart!;

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: cart.items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Dismissible(
                            key: Key('cart_item_${item.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Remove Item'),
                                  content: Text('Remove ${item.product.name} from cart?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) {
                              cartProvider.removeItem(item.id);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailScreen(
                                          product: item.product,
                                          initialVariantId: item.variantId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: (item.product.images.isNotEmpty || item.product.imageUrl != null)
                                              ? Image.network(
                                                  item.product.images.isNotEmpty
                                                      ? item.product.images.first
                                                      : item.product.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    decoration: BoxDecoration(
                                                      gradient: AppColors.primaryGradient,
                                                    ),
                                                    child: const Center(
                                                      child: Icon(Icons.shopping_bag, color: Colors.white70),
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  decoration: BoxDecoration(
                                                    gradient: AppColors.primaryGradient,
                                                  ),
                                                  child: const Center(
                                                    child: Icon(Icons.shopping_bag, color: Colors.white70),
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.product.name,
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () async {
                                                       await cartProvider.removeItem(item.id);
                                                    },
                                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                    iconSize: 20,
                                                    tooltip: 'Remove',
                                                  ),
                                                ],
                                              ),
                                              if (item.variantName != null || item.variantAttributes != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${item.variantName ?? ''} ${item.variantAttributes != null ? "(${item.variantAttributes})" : ""}'.trim(),
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatCurrency(item.price),
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  color: theme.colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.surfaceContainerHighest,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      onPressed: () {
                                                        if (item.quantity > 1) {
                                                          cartProvider.updateQuantity(item.id, item.quantity - 1);
                                                        } else {
                                                          cartProvider.removeItem(item.id);
                                                        }
                                                      },
                                                      icon: const Icon(Icons.remove),
                                                      iconSize: 18,
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(
                                                        minWidth: 32,
                                                        minHeight: 32,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                      child: Text(
                                                        '${item.quantity}',
                                                        style: theme.textTheme.bodyMedium?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () => cartProvider.updateQuantity(
                                                        item.id,
                                                        item.quantity + 1,
                                                      ),
                                                      icon: const Icon(Icons.add),
                                                      iconSize: 18,
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(
                                                        minWidth: 32,
                                                        minHeight: 32,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  _formatCurrency(cart.totalAmount),
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CheckoutScreen(),
                                    ),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ).copyWith(
                                  backgroundColor: WidgetStateProperty.resolveWith((states) => null),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: const Text('Proceed to Checkout', 
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
