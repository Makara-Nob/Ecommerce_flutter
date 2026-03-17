import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/home_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import 'all_products_screen.dart';
import '../../widgets/gradient_background.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'All Categories',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Grid Body ────────────────────────────────────────────────────
          Expanded(
            child: Consumer<HomeProvider>(
              builder: (context, homeProvider, _) {
                if (homeProvider.isLoading && homeProvider.categories.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (homeProvider.categories.isEmpty) {
                  return const Center(child: Text('No categories found'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: homeProvider.categories.length,
                  itemBuilder: (context, index) {
                    final cat = homeProvider.categories[index];
                    return GestureDetector(
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: cat.icon != null && cat.icon!.isNotEmpty
                                    ? Image.network(
                                        cat.icon!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey[100],
                                          child: const Icon(Icons.category_rounded, color: Colors.grey, size: 40),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[100],
                                        child: const Icon(Icons.category_rounded, color: Colors.grey, size: 40),
                                      ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.center,
                                child: Text(
                                  cat.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (index * 50).ms).scale(begin: const Offset(0.9, 0.9));
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
