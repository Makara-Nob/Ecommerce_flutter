import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'order_success_screen.dart';
import 'aba_webview_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';

class AbaCheckoutScreen extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic> paywayPayload;
  final String paywayApiUrl;

  const AbaCheckoutScreen({
    super.key,
    required this.orderId,
    required this.paywayPayload,
    required this.paywayApiUrl,
  });

  @override
  State<AbaCheckoutScreen> createState() => _AbaCheckoutScreenState();
}

class _AbaCheckoutScreenState extends State<AbaCheckoutScreen> {
  bool _isLoading = false;
  int _currentStep = 0; // 0 = Selector, 1 = KHQR Display
  bool _isCheckingPayment = false;
  String? _errorMessage;
  
  String? _qrImageBase64;
  String? _deeplink;
  String? _qrString;
  String? _amount;
  String? _tranId;
  String _selectedMethod = 'khqr'; // 'khqr' or 'card'

  @override
  void initState() {
    super.initState();
    _amount = widget.paywayPayload['amount']?.toString();
  }

  Future<void> _fetchAbaPaymentDetails() async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(widget.paywayApiUrl));
      
      widget.paywayPayload.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (!mounted) return;

      if (data['status']?['code'] == '00') {
        setState(() {
          _isLoading = false;
          // Extract the base64 part: "data:image/png;base64,iVBORw0KGgo..."
          final qrImageRaw = data['qrImage'] as String?;
          if (qrImageRaw != null && qrImageRaw.contains(',')) {
            _qrImageBase64 = qrImageRaw.split(',')[1];
          }
          _deeplink = data['abapay_deeplink'];
          _qrString = data['qrString'];
          _tranId = data['status']['tran_id'];
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = data['status']?['message'] ?? 'Payment initialization failed';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to connect to ABA PayWay: $e';
      });
    }
  }

  Future<void> _verifyPayment() async {
    if (_isCheckingPayment) return;

    setState(() => _isCheckingPayment = true);

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final success = await orderProvider.checkPaymentStatus(widget.orderId);

      if (!mounted) return;

      if (success) {
        final order = orderProvider.currentOrder;
        if (order?.status == 'CONFIRMED') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
          );
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment is still pending. Please wait a moment or try again.'),
              backgroundColor: AppColors.primaryStart,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.errorMessage ?? 'Could not verify payment status'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingPayment = false);
    }
  }

  Future<void> _launchAbaApp() async {
    if (_deeplink == null) return;
    final uri = Uri.parse(_deeplink!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch ABA Mobile App. Please scan the QR code instead.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(_currentStep == 1 ? Icons.arrow_back : Icons.close),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() {
                _currentStep = 0;
                _isLoading = false;
                _errorMessage = null;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: _currentStep == 0
        ? _buildSelectionScreen(theme)
        : _isLoading 
          ? _buildLoadingState()
          : _errorMessage != null
            ? _buildErrorState()
            : _buildKhqrSection(theme),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryStart),
          const SizedBox(height: 24),
          const Text('Generating secure payment...', 
            style: TextStyle(color: AppColors.textSecondaryLight),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.errorLight),
            const SizedBox(height: 16),
            const Text('Payment Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 32),
            SizedBox(
              width: 150,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryStart),
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildSelectionScreen(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderSummary(theme),
          const SizedBox(height: 32),
          Text(
            'Choose way to pay',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
          const SizedBox(height: 16),
          _buildPaymentMethodTile(
            id: 'khqr',
            title: 'ABA KHQR',
            subtitle: 'Scan to pay with any banking app',
            svgAsset: 'assets/images/payment/ABA_BANK_khqr.svg',
            onTap: () {
              setState(() {
                _selectedMethod = 'khqr';
                _currentStep = 1;
                _isLoading = true;
                _errorMessage = null;
              });
              _fetchAbaPaymentDetails();
            },
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodTile(
            id: 'card',
            title: 'Credit/Debit Card',
            subtitleWidget: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SvgPicture.asset(
                'assets/images/payment/aba_card_group.svg',
                height: 18,
                alignment: Alignment.centerLeft,
              ),
            ),
            svgAsset: 'assets/images/payment/cards_icons.svg',
            onTap: () {
              setState(() => _selectedMethod = 'card');
              _navigateToCardCheckout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total to Pay', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
              const SizedBox(height: 4),
              Text('\$${_amount ?? "0.00"}', 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryStart.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Order #${widget.orderId}',
              style: const TextStyle(color: AppColors.primaryStart, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String id,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    required String svgAsset,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              alignment: Alignment.center,
              child: SvgPicture.asset(
                svgAsset,
                width: svgAsset.contains('khqr') ? 50 : 40,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (subtitleWidget != null)
                    subtitleWidget
                  else if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildKhqrSection(ThemeData theme) {
    return Column(
      children: [
        _buildQrCard(theme),
        const SizedBox(height: 32),
        _buildAbaPayButton(),
        const SizedBox(height: 16),
        _buildPaymentConfirmButton(),
      ],
    ).animate().fadeIn();
  }

  Widget _buildQrCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryStart.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_qrImageBase64 != null)
            Image.memory(
              base64Decode(_qrImageBase64!),
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack)
          else
            const SizedBox(
              width: 250,
              height: 250,
              child: Center(child: Icon(Icons.qr_code_scanner, size: 64, color: AppColors.textTertiaryLight)),
            ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Transaction ID', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
              Text(_tranId ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbaPayButton() {
    if (_deeplink == null) return const SizedBox.shrink();
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _launchAbaApp,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryStart,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        icon: const Icon(Icons.open_in_new),
        label: const Text('Open ABA Mobile App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildPaymentConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _isCheckingPayment ? null : _verifyPayment,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primaryStart, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isCheckingPayment
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('I have made the payment', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryStart)
              ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  void _navigateToCardCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AbaWebViewScreen(
          paywayPayload: widget.paywayPayload,
          paywayApiUrl: widget.paywayApiUrl,
        ),
      ),
    ).then((_) => _verifyPayment());
  }
}
