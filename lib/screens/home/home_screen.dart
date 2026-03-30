import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../products/product_list_screen.dart';
import '../cart/cart_screen.dart';
import '../orders/order_list_screen.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Provider.of<ProductProvider>(context, listen: false).loadProducts();
      } catch (e) {
        debugPrint('Error loading products: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, CartProvider>(
      builder: (context, authProvider, cartProvider, _) {
        final isLoggedIn = authProvider.isAuthenticated;
        final cartCount = cartProvider.itemCount;

        // Build screens & nav items based on auth state
        final screens = [
          const ProductListScreen(),
          const CartScreen(showBackButton: false),
          const OrderListScreen(
            showBackButton: false,
            showFilter: false,
            initialStatus: 'PAID',
          ),
          const ProfileScreen(),
        ];

        final navItems = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('$cartCount'),
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: Badge(
              label: Text('$cartCount'),
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];

        // Ensure selected index is safe
        final safeIndex = _selectedIndex.clamp(0, screens.length - 1);

        return Scaffold(
          body: IndexedStack(
            index: safeIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: safeIndex,
              onTap: (index) {
                final label = navItems[index].label;
                // Pages that require authentication
                if ((label == 'Wishlist' || label == 'Cart' || label == 'Orders') && !isLoggedIn) {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                   return;
                }
                setState(() => _selectedIndex = index);
              },
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: navItems,
            ),
          ),
        );
      },
    );
  }
}
