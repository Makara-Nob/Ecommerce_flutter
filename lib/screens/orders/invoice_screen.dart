// ➕ NEW — Full invoice screen shown after payment is verified as paid
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/order/order.dart';
import '../../models/order/order_item.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';

class InvoiceScreen extends StatefulWidget {
  final Order order;

  const InvoiceScreen({super.key, required this.order});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen>
    with SingleTickerProviderStateMixin {
  // ➕ NEW — AnimationController for the checkmark (800 ms as spec'd)
  late AnimationController _checkController;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  String _fmt(double? amount) =>
      amount != null ? NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount) : 'N/A';

  String _fmtDate(DateTime? dt) =>
      dt != null ? DateFormat('MMM d, yyyy • h:mm a').format(dt) : 'N/A';

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Invoice',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // ── 1. Success Header ────────────────────────────────────────────
            _buildSuccessHeader(order).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 16),

            // ── 2. Customer Info ─────────────────────────────────────────────
            _buildSection(
              title: 'CUSTOMER INFO',
              icon: Icons.person_outline,
              child: _buildCustomerInfo(order, user),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),

            // ── 3. Order Items ───────────────────────────────────────────────
            _buildSection(
              title: 'ORDER ITEMS',
              icon: Icons.shopping_bag_outlined,
              child: _buildOrderItems(order.items, theme),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),

            // ── 4. Payment Summary ───────────────────────────────────────────
            _buildSection(
              title: 'PAYMENT SUMMARY',
              icon: Icons.receipt_long_outlined,
              child: _buildPaymentSummary(order),
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 28),

            // ── 5. Action Buttons ────────────────────────────────────────────
            _buildActions(context)
                .animate()
                .fadeIn(delay: 450.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── 1. Success Header Widget ───────────────────────────────────────────────
  Widget _buildSuccessHeader(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.successLight.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ➕ NEW — animated checkmark via ScaleTransition
          ScaleTransition(
            scale: _checkScale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.successGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.successLight.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 44),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Payment Successful',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.successLight,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Order #${order.id}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryStart,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Paid on: ${_fmtDate(order.updatedAt ?? order.createdAt)}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),

          if (order.invoiceNumber != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryStart.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.invoiceNumber!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryStart,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 2. Customer Info Widget ────────────────────────────────────────────────
  Widget _buildCustomerInfo(Order order, dynamic user) {
    return Column(
      children: [
        _buildInfoRow(Icons.person, 'Name', user?.fullName ?? 'N/A'),
        const Divider(height: 20, color: Color(0xFFEEEEEE)),
        _buildInfoRow(Icons.email_outlined, 'Email', user?.email ?? 'N/A'),
        const Divider(height: 20, color: Color(0xFFEEEEEE)),
        _buildInfoRow(
          Icons.location_on_outlined,
          'Shipping Address',
          order.deliveryAddress ?? 'N/A',
        ),
        if (order.deliveryPhone != null) ...[
          const Divider(height: 20, color: Color(0xFFEEEEEE)),
          _buildInfoRow(Icons.phone_outlined, 'Phone', order.deliveryPhone!),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryStart),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimaryLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 3. Order Items Widget ──────────────────────────────────────────────────
  Widget _buildOrderItems(List<OrderItem> items, ThemeData theme) {
    if (items.isEmpty) {
      return const Text('No items', style: TextStyle(color: Colors.grey));
    }
    return Column(
      children: items.asMap().entries.map((e) {
        final item = e.value;
        final isLast = e.key == items.length - 1;
        final imageUrl = item.product.images.isNotEmpty
            ? item.product.images.first
            : item.product.imageUrl;

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[100],
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.shopping_bag, color: Colors.grey),
                          )
                        : const Icon(Icons.shopping_bag, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name.isNotEmpty ? item.product.name : 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_fmt(item.price)} × ${item.quantity}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            _fmt(item.subtotal),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryStart,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isLast) const Divider(height: 20, color: Color(0xFFEEEEEE)),
          ],
        );
      }).toList(),
    );
  }

  // ── 4. Payment Summary Widget ──────────────────────────────────────────────
  Widget _buildPaymentSummary(Order order) {
    final subtotal = order.totalAmount;
    final discount = order.discountAmount ?? 0.0;
    final total = order.netAmount ?? order.totalAmount;

    return Column(
      children: [
        _buildSummaryRow('Subtotal', _fmt(subtotal)),
        const SizedBox(height: 8),
        _buildSummaryRow('Shipping', 'Free'),
        if (discount > 0) ...[
          const SizedBox(height: 8),
          _buildSummaryRow('Discount', '- ${_fmt(discount)}',
              valueColor: AppColors.successLight),
        ],
        const SizedBox(height: 12),
        const Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
        const SizedBox(height: 12),

        // Total — bold, large, green
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            Text(
              _fmt(total),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.successLight,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        const Divider(color: Color(0xFFEEEEEE)),
        const SizedBox(height: 8),

        _buildSummaryRow('Payment Method', order.paymentMethod ?? 'N/A'),
        if (order.notes != null && order.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSummaryRow('Notes', order.notes!),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  // ── 5. Action Buttons ──────────────────────────────────────────────────────
  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        // ➕ NEW — Back to Home: clears full navigation stack
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => HomeScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to Home'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: AppColors.primaryStart, width: 1.5),
              foregroundColor: AppColors.primaryStart,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // ➕ NEW — Download placeholder (bonus PDF can be wired here)
        Expanded(
          child: FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF download coming soon!'),
                  backgroundColor: AppColors.primaryStart,
                ),
              );
            },
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            label: const Text('Download'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: AppColors.primaryStart,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared Section Wrapper ─────────────────────────────────────────────────
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryStart),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryStart,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
