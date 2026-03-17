import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/address_provider.dart';
import '../../theme/app_colors.dart';
import 'add_edit_address_screen.dart';
import '../../widgets/shimmer_loading.dart';
import '../../utils/toast_helper.dart';

class AddressListScreen extends StatefulWidget {
  final bool isSelectionMode;
  const AddressListScreen({super.key, this.isSelectionMode = false});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AddressProvider>(context, listen: false).loadAddresses();
    });
  }

  void _confirmDelete(BuildContext context, int addressId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await Provider.of<AddressProvider>(context, listen: false).deleteAddress(addressId);
              if (mounted) {
                if (success) {
                  ToastHelper.success(context, 'Address deleted');
                } else {
                  ToastHelper.error(context, 'Failed to delete address');
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.errorLight)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? 'Select Address' : 'My Addresses', 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<AddressProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.addresses.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: const ListItemShimmer(),
              ),
            );
          }

          if (provider.addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No addresses saved yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add an address to make checkout faster.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primaryStart,
            onRefresh: () => provider.loadAddresses(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.addresses.length,
              itemBuilder: (context, index) {
                final address = provider.addresses[index];
                final isSelected = widget.isSelectionMode && address.isDefault;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected 
                        ? Border.all(color: AppColors.primaryStart, width: 2)
                        : Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (widget.isSelectionMode) {
                        Navigator.pop(context, address);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditAddressScreen(address: address),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: address.isDefault
                                      ? AppColors.primaryStart.withOpacity(0.1)
                                      : Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  address.title.toLowerCase().contains('home') 
                                      ? Icons.home_rounded 
                                      : address.title.toLowerCase().contains('work') 
                                          ? Icons.work_rounded 
                                          : Icons.location_on_rounded,
                                  color: address.isDefault ? AppColors.primaryStart : Colors.grey[600],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          address.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (address.isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryStart.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Default',
                                              style: TextStyle(
                                                color: AppColors.primaryStart,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      address.recipientName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      address.phoneNumber,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${address.streetAddress}, ${address.city}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                    ),
                                    if (address.state != null || address.zipCode != null)
                                      Text(
                                        '${address.state ?? ''} ${address.zipCode ?? ''}'.trim(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                          height: 1.4,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!widget.isSelectionMode)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddEditAddressScreen(address: address),
                                        ),
                                      );
                                    } else if (value == 'delete') {
                                      _confirmDelete(context, address.id);
                                    } else if (value == 'set_default') {
                                      final success = await provider.setDefaultAddress(address.id);
                                      if (mounted && success) {
                                        ToastHelper.success(context, 'Set as default address');
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (!address.isDefault)
                                      const PopupMenuItem(
                                        value: 'set_default',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                                            SizedBox(width: 12),
                                            Text('Set as Default'),
                                          ],
                                        ),
                                      ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                                          SizedBox(width: 12),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                          SizedBox(width: 12),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditAddressScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryStart,
        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
        label: const Text('Add Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
