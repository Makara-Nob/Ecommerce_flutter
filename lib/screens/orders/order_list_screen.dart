import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/brand_logo.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  final bool showBackButton;
  final bool showFilter;
  final String? initialStatus;
  const OrderListScreen({
    super.key, 
    this.showBackButton = true,
    this.showFilter = true,
    this.initialStatus,
  });

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedStatus;

  final List<String> _statuses = [
    'ALL',
    'PENDING',
    'PROCESSING',
    'SHIPPED',
    'DELIVERED',
    'CANCELLED',
  ];

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    try {
      return DateFormat('MMM dd, yyyy • HH:mm').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'PROCESSING': return Colors.blue;
      case 'SHIPPED': return Colors.indigo;
      case 'DELIVERED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus ?? 'ALL';
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).loadOrders(
        refresh: true,
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      if (!orderProvider.isFetchingMore && orderProvider.hasMore) {
        orderProvider.loadMoreOrders(status: _selectedStatus == 'ALL' ? null : _selectedStatus);
      }
    }
  }

  void _onStatusChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    Provider.of<OrderProvider>(context, listen: false).loadOrders(
      refresh: true,
      status: status == 'ALL' ? null : status,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ── Glassmorphic App Bar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GlassContainer(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(vertical: 2),
              blur: 15,
              opacity: 0.08,
              borderRadius: BorderRadius.circular(30),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                        'My Orders',
                        style: TextStyle(
                          color: AppColors.textPrimaryLight,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Provider.of<OrderProvider>(context, listen: false).loadOrders(
                          refresh: true, 
                          status: _selectedStatus == 'ALL' ? null : _selectedStatus
                        ),
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimaryLight),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn().slideY(begin: -0.1),

          // ── Filter Bar ──────────────────────────────────────────────────────
          if (widget.showFilter)
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _statuses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final status = _statuses[index];
                  final isSelected = (_selectedStatus ?? 'ALL') == status;
                  return Center(
                    child: AnimatedContainer(
                      duration: 300.ms,
                      child: ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) _onStatusChanged(status);
                        },
                        selectedColor: AppColors.primaryStart,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white,
                        elevation: 0,
                        pressElevation: 0,
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryStart : Colors.grey[200]!,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        showCheckmark: false,
                      ),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 200.ms),

          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (orderProvider.orders.isEmpty) {
                  return EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No orders found',
                    description: _selectedStatus == null || _selectedStatus == 'ALL' 
                      ? 'Your order history will appear here once you make a purchase'
                      : 'You have no orders with status: $_selectedStatus',
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: orderProvider.orders.length + (orderProvider.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    if (index == orderProvider.orders.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final order = orderProvider.orders[index];
                    return _OrderCard(
                      order: order,
                      formatDate: _formatDate,
                      formatCurrency: _formatCurrency,
                      statusColor: _getStatusColor(order.status),
                    ).animate().fadeIn(delay: (index % 10 * 50).ms).slideX(begin: 0.1, end: 0);
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

class _OrderCard extends StatelessWidget {
  final dynamic order;
  final String Function(DateTime?) formatDate;
  final String Function(double) formatCurrency;
  final Color statusColor;

  const _OrderCard({
    required this.order,
    required this.formatDate,
    required this.formatCurrency,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final orderId = order.id.toString();
                            final displayId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
                            return Text(
                              'Order #${displayId.toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(order.createdAt),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: Colors.grey[400], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                      style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      formatCurrency(order.totalAmount),
                      style: const TextStyle(
                        color: AppColors.primaryStart,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
