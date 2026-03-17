import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/address_provider.dart';
import '../../models/address/address_model.dart';
import '../../theme/app_colors.dart';
import '../profile/address_list_screen.dart';
import 'order_success_screen.dart';
import 'aba_checkout_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  
  AddressModel? _selectedAddress;
  bool _isLoading = false;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
      if (addressProvider.addresses.isEmpty && !addressProvider.isLoading) {
        addressProvider.loadAddresses().then((_) {
          if (mounted) {
            setState(() {
              _selectedAddress = addressProvider.defaultAddress;
            });
          }
        });
      } else {
        _selectedAddress = addressProvider.defaultAddress;
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address'), backgroundColor: AppColors.errorLight),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      // Map cart items to the format expected by the backend
      final cart = cartProvider.cart;
      if (cart == null) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart is empty')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final items = cart.items.map((item) => {
        'productId': item.product.id,
        'quantity': item.quantity,
      }).toList();

      final fullAddressString = '${_selectedAddress!.streetAddress}, ${_selectedAddress!.city}' + 
          (_selectedAddress!.state != null ? ', ${_selectedAddress!.state}' : '') +
          (_selectedAddress!.zipCode != null ? ' ${_selectedAddress!.zipCode}' : '');

      final success = await orderProvider.createOrder(
        deliveryAddress: fullAddressString,
        deliveryPhone: _selectedAddress!.phoneNumber,
        notes: _noteController.text,
        items: items,
        paymentMethod: 'ABA_PAYWAY', // Defaulting to Aba
      );

      if (!mounted) return;

      if (success) {
        cartProvider.clearLocalCart();
        
        final order = orderProvider.currentOrder;
        
        if (order != null && order.paywayPayload != null && order.paywayApiUrl != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AbaCheckoutScreen(
                orderId: order.id,
                paywayPayload: order.paywayPayload!,
                paywayApiUrl: order.paywayApiUrl!,
              ),
            ),
          );
        } else {
           Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const OrderSuccessScreen(),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.errorMessage ?? 'Failed to place order'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorLight,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Shipping Details',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ).animate().fadeIn().slideX(),
              const SizedBox(height: 8),
              Text(
                'Please enter your delivery information',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(),
              const SizedBox(height: 32),

              // Delivery Address Selector
              _buildSectionTitle(context, 'Delivery Address', Icons.location_on_outlined),
              const SizedBox(height: 16),
              
              InkWell(
                onTap: () async {
                  final result = await Navigator.push<AddressModel>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddressListScreen(isSelectionMode: true),
                    ),
                  );
                  if (result != null) {
                    setState(() => _selectedAddress = result);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _selectedAddress == null ? AppColors.errorLight : Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryStart.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: AppColors.primaryStart),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _selectedAddress == null 
                          ? const Text(
                              'Select a delivery address',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _selectedAddress!.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (_selectedAddress!.isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryStart.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Default',
                                          style: TextStyle(color: AppColors.primaryStart, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    ]
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedAddress!.recipientName} • ${_selectedAddress!.phoneNumber}',
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedAddress!.streetAddress}, ${_selectedAddress!.city}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              
              if (_selectedAddress == null) ...[
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text('Address is required', style: TextStyle(color: AppColors.errorLight, fontSize: 12)),
                )
              ],
              const SizedBox(height: 24),

              // Note Field
              _buildSectionTitle(context, 'Additional Notes', Icons.note_alt_outlined),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Gate code, delivery instructions, etc.',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                maxLines: 2,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 48),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Place Order',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ).animate().fadeIn(delay: 500.ms).scale(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ).animate().fadeIn().slideX();
  }
}
