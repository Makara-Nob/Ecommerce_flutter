import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../home/home_screen.dart';
import 'edit_profile_screen.dart';
import 'address_list_screen.dart';
import 'saved_cards_screen.dart';
import 'wishlist_screen.dart';
import '../../providers/wishlist_provider.dart';
import '../orders/order_list_screen.dart';
import '../../widgets/glass_container.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for contrast
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isAuthenticated) {
            return _buildGuestView(context);
          }
          return _buildUserView(context, authProvider);
        },
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(
            'Welcome!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 12),
          Text(
            'Sign in to view your profile, orders,\nand wishlist.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ).animate().fadeIn(delay: 400.ms).scale(),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ).animate().fadeIn(delay: 500.ms).scale(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserView(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.currentUser;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Modern Floating Header
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              blur: 20,
              opacity: 0.1,
              borderRadius: BorderRadius.circular(32),
              child: Row(
                children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryStart.withOpacity(0.1),
                        backgroundImage: (user?.profileUrl != null && user!.profileUrl!.isNotEmpty)
                            ? NetworkImage(user!.profileUrl!)
                            : null,
                        child: (user?.profileUrl == null || user!.profileUrl!.isEmpty)
                            ? Text(
                                user?.fullName?.isNotEmpty == true
                                    ? user!.fullName![0].toUpperCase()
                                    : (user?.username?.isNotEmpty == true
                                        ? user!.username![0].toUpperCase()
                                        : 'U'),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryStart,
                                ),
                              )
                            : null,
                      ),
                    ),
                  const SizedBox(width: 20),
                  // Names
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'User',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        if (user?.username != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '@${user!.username}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primaryEnd,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideY(begin: -0.1),

          const SizedBox(height: 24),

          // Menu Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 12),
                  child: Text(
                    'Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                _buildMenuCard(context, [
                  _buildMenuItem(context, Icons.person_outline, 'Personal Information', 
                    subtitle: 'Manage your personal details',
                    onTap: () => _navigateToEditProfile(context)),
                    
                  const Divider(height: 1, indent: 64),

                  _buildMenuItem(context, Icons.favorite_outline_rounded, 'My Wishlist',
                    subtitle: 'Items you have saved',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WishlistScreen(),
                        ),
                      );
                    }),
                    
                  const Divider(height: 1, indent: 64),

                  _buildMenuItem(context, Icons.receipt_long_outlined, 'My Orders',
                    subtitle: 'Track and manage your purchases',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrderListScreen(),
                        ),
                      );
                    }),
                    
                  const Divider(height: 1, indent: 64),
                  
                  _buildMenuItem(context, Icons.location_on_outlined, 'My Addresses',
                    subtitle: 'Manage your delivery locations',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddressListScreen(),
                        ),
                      );
                    }),

                  const Divider(height: 1, indent: 64),

                  _buildMenuItem(context, Icons.credit_card_outlined, 'Saved Cards',
                    subtitle: 'Pay faster with stored cards',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedCardsScreen(),
                        ),
                      );
                    }),
                ]),

                const SizedBox(height: 32),
                
                // Logout
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure you want to sign out?'),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(backgroundColor: AppColors.errorLight),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        // Clear Cart State
                        if (context.mounted) {
                           Provider.of<CartProvider>(context, listen: false).clearLocalCart();
                           Provider.of<WishlistProvider>(context, listen: false).clear();
                        }
                        
                        await authProvider.logout();
                        
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.errorLight,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, {String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryStart, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }
}
