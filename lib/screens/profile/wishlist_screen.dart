import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_background.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import '../products/product_detail_screen.dart';
import '../home/home_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Gradient App Bar
          GradientBackground(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    const Icon(Icons.favorite, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'My Wishlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: Consumer<WishlistProvider>(
              builder: (context, wishlist, _) {
                if (wishlist.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (wishlist.items.isEmpty) {
                  return EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'Your Wishlist is Empty',
                    description: 'Save items you love to find them easily later.',
                    actionLabel: 'Go Shopping',
                    onAction: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: wishlist.items.length,
                  itemBuilder: (context, index) {
                    final product = wishlist.items[index];
                    return ProductCard(
                      product: product,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: product),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
