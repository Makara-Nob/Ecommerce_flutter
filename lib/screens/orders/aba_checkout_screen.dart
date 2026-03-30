import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'order_success_screen.dart';
import 'aba_webview_screen.dart';
import 'aba_khqr_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../../services/card_service.dart';
import '../../models/payment/saved_card.dart';
import '../profile/saved_cards_screen.dart';

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

class _AbaCheckoutScreenState extends State<AbaCheckoutScreen> with WidgetsBindingObserver {
  bool _isCheckingPayment = false;
  bool _isWaitingForReturn = false;
  bool _isPayingByToken = false;
  String? _amount;
  List<SavedCard> _savedCards = [];
  final _cardService = CardService();

  @override
  void initState() {
    super.initState();
    _amount = widget.paywayPayload['amount']?.toString();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    try {
      final cards = await _cardService.getSavedCards();
      if (mounted) setState(() => _savedCards = cards);
    } catch (e) {
      debugPrint('Error loading saved cards: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from ABA app, auto-verify payment
    if (state == AppLifecycleState.resumed && _isWaitingForReturn) {
      _isWaitingForReturn = false;
      // Small delay to let ABA backend process the payment
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _verifyPayment();
      });
    }
  }

  Future<bool> _verifyPayment({bool silent = false}) async {
    if (_isCheckingPayment) return false;

    if (!silent) setState(() => _isCheckingPayment = true);

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final success = await orderProvider.checkPaymentStatus(widget.orderId);

      if (!mounted) return false;

      if (success) {
        final order = orderProvider.currentOrder;
        if (order?.status == 'CONFIRMED') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
          );
          return true; // ➕ stop KHQR polling
        } else if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment is still pending. Please wait a moment or try again.'),
              backgroundColor: AppColors.primaryStart,
            ),
          );
        }
      } else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.errorMessage ?? 'Could not verify payment status'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    } finally {
      if (mounted && !silent) setState(() => _isCheckingPayment = false);
    }
    return false;
  }

  void _navigateToAbaCheckout(String abaOption, String methodName) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    // DEBUG SNACK
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting $methodName flow (Option: $abaOption)...')),
    );

    // 1. Fetch fresh payload from backend to get correct hash
    final result = await orderProvider.getPaywayPayload(widget.orderId, abaOption);
    
    if (!mounted) return;

    if (result != null) {
      final paywayPayload = result['paywayPayload'] as Map<String, dynamic>;
      final paywayApiUrl = result['paywayApiUrl'] as String;

      // Show loading indicator while waiting for ABA response
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        print('POSTing to ABA: $paywayApiUrl with option: $abaOption');
        final response = await http.post(
          Uri.parse(paywayApiUrl),
          body: paywayPayload,
        );

        if (!mounted) return;
        Navigator.pop(context); // Remove loading dialog

        print('ABA Response Status: ${response.statusCode}');
        print('ABA Response Headers: ${response.headers}');

        if (response.statusCode == 200) {
          final String body = response.body.trim();
          final String contentType = response.headers['content-type'] ?? '';
          
          bool isJson = contentType.contains('application/json') || (body.startsWith('{') && body.endsWith('}'));
          
          if (isJson) {
            final jsonResponse = jsonDecode(body);
            
            if (jsonResponse['status']['code'] == '00') {
              final String? paymentUrl = jsonResponse['payment_link'] ?? 
                                         jsonResponse['checkout_url'] ?? 
                                         jsonResponse['url'] ??
                                         jsonResponse['abapay_deeplink']; // ✅ Support specific deeplink field
              
              print('ABA Response for $abaOption:');
              print(' - paymentUrl: $paymentUrl');
              print(' - abapay_deeplink: ${jsonResponse['abapay_deeplink']}');
              print(' - hasQrImage: ${jsonResponse.containsKey('qrImage')}');

              // If user DID NOT choose KHQR explicitly, prioritize the web/app link
              if (abaOption != 'abapay_khqr' && paymentUrl != null && paymentUrl.isNotEmpty) {
                if (!paymentUrl.startsWith('http')) {
                  print(' -> Launching Direct Deeplink: $paymentUrl');
                  try {
                    bool launched = await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
                    if (!launched) {
                      throw Exception('Could not launch the ABA Mobile app. Is it installed?');
                    }
                    // Mark that we're waiting for user to return from ABA app
                    setState(() => _isWaitingForReturn = true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Complete payment in ABA app, then return here.'),
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open ABA Mobile app. Please ensure it is installed.'),
                          backgroundColor: AppColors.errorLight,
                        ),
                      );
                    }
                  }
                  return;
                }
                print(' -> Navigating to WebView/Deeplink (URL priority)');
                _openWebView(null, null, methodName, initialUrl: paymentUrl);
                return;
              }

              // Otherwise, if there is a QR image, show our custom QR screen
              // BUT ONLY if the user actually requested KHQR
              if (abaOption == 'abapay_khqr' && jsonResponse.containsKey('qrImage')) {
                print(' -> Navigating to Custom QR Screen');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AbaKhqrScreen(
                      qrImage: jsonResponse['qrImage'],
                      qrString: jsonResponse['qrString'],
                      amount: paywayPayload['amount'] ?? '0.00',
                      tranId: paywayPayload['tran_id'] ?? jsonResponse['status']['tran_id'] ?? 'N/A',
                      onVerify: _verifyPayment,
                    ),
                  ),
                );
                return;
              }
              
              // Fallback to URL if we are here (either no QR or it wasn't a KHQR request)
              if (paymentUrl != null && paymentUrl.isNotEmpty) {
                if (!paymentUrl.startsWith('http')) {
                  print(' -> Launching Direct Deeplink (Fallback): $paymentUrl');
                  try {
                    bool launched = await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
                    if (!launched) {
                      throw Exception('Could not launch the ABA Mobile app. Is it installed?');
                    }
                    // Mark that we're waiting for user to return from ABA app
                    setState(() => _isWaitingForReturn = true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Complete payment in ABA app, then return here.'),
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open ABA Mobile app. Please ensure it is installed.'),
                          backgroundColor: AppColors.errorLight,
                        ),
                      );
                    }
                  }
                  return;
                }
                print(' -> Navigating to WebView/Deeplink (Fallback)');
                _openWebView(null, null, methodName, initialUrl: paymentUrl);
                return;
              }

              // If JSON but no QR data and no URL, it might be an error or different format
              throw Exception('Success message found but no redirect data. Response: $body');
            } else {
              throw Exception('ABA Error (${jsonResponse['status']['code']}): ${jsonResponse['status']['message']}. Response: $body');
            }
          } else {
            // It's HTML, load it directly in WebView
            _openWebView(null, null, methodName, htmlContent: body);
          }
        } else if (response.statusCode == 302 || response.statusCode == 301 || response.statusCode == 307 || response.statusCode == 308) {
          // Handle redirect manually (common for COF point to card entry page)
          final String? location = response.headers['location'];
          if (location != null && location.isNotEmpty) {
            _openWebView(null, null, methodName, initialUrl: location);
          } else {
            throw Exception('Redirect received (code ${response.statusCode}) but no Location header found.');
          }
        } else {
          throw Exception('Server responded with status code ${response.statusCode}. Body: ${response.body}');
        }
      } catch (e) {
        if (!mounted) return;
        if (Navigator.canPop(context)) Navigator.pop(context); // Safety pop
        
        final String errorMsg = e.toString();
        print('❌ ABA Payment Error: $errorMsg');

        if (errorMsg.contains('Response:')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Payment Debug Info'),
              content: SingleChildScrollView(
                child: SelectableText(errorMsg),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment Error: $errorMsg'),
              backgroundColor: AppColors.errorLight,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Failed to initialize payment'),
          backgroundColor: AppColors.errorLight,
        ),
      );
    }
  }

  void _openWebView(Map<String, dynamic>? payload, String? url, String name, {String? htmlContent, String? initialUrl}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AbaWebViewScreen(
          paywayPayload: payload,
          paywayApiUrl: url,
          methodName: name,
          htmlContent: htmlContent,
          initialUrl: initialUrl,
        ),
      ),
    ).then((_) => _verifyPayment());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimaryLight,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Column(
            children: [
              // Waiting banner shown while user is in ABA app
              if (_isWaitingForReturn)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: const Color(0xFFC6A664).withOpacity(0.15),
                  child: const Row(
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC6A664))),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Waiting for ABA payment… Return here after completing.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF8B6914), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
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
                        title: 'ABA KHQR',
                        subtitle: 'Scan to pay with any banking app',
                        svgAsset: 'assets/images/payment/ABA_BANK_khqr.svg',
                        onTap: () => _navigateToAbaCheckout('abapay_khqr', 'ABA KHQR'),
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentMethodTile(
                        title: 'ABA Mobile App',
                        subtitle: 'Open ABA app to pay instantly',
                        svgAsset: 'assets/images/payment/ABA_BANK_khqr.svg',
                        onTap: () => _navigateToAbaCheckout('abapay_deeplink', 'ABA Mobile App'),
                      ),
                      const SizedBox(height: 12),
                      // Saved card tiles
                      ..._savedCards.asMap().entries.map((entry) =>
                        _buildSavedCardTile(entry.value),
                      ),
                      // Manage / add cards shortcut
                      _buildPaymentMethodTile(
                        title: _savedCards.isEmpty ? 'Pay with Card' : 'Add / Manage Cards',
                        subtitle: _savedCards.isEmpty
                            ? 'Link your card for faster checkout'
                            : 'Link a new card or remove existing',
                        svgAsset: 'assets/images/payment/cards_icons.svg',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SavedCardsScreen()),
                          );
                          _loadSavedCards(); // refresh after returning
                        },
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (orderProvider.isLoading && !_isCheckingPayment)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryStart),
            ),
          ),
      ],
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

  Future<void> _payByToken(SavedCard card) async {
    if (_isPayingByToken) return;
    setState(() => _isPayingByToken = true);

    try {
      final success = await _cardService.payByToken(widget.orderId, card.index);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPayingByToken = false);
    }
  }

  Widget _buildSavedCardTile(SavedCard card) {
    final isVisa = card.cardType.toLowerCase() == 'visa';
    final isMC = card.cardType.toLowerCase() == 'mc' ||
        card.cardType.toLowerCase() == 'mastercard';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _isPayingByToken ? null : () => _payByToken(card),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isVisa
                  ? [const Color(0xFF1A1F71), const Color(0xFF1565C0)]
                  : isMC
                      ? [const Color(0xFF1B1B1B), const Color(0xFF333333)]
                      : [AppColors.primaryStart, AppColors.primaryEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  card.brandIcon,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isVisa ? const Color(0xFF1A1F71) : Colors.black87,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.maskPan,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap to pay instantly',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (_isPayingByToken)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(Icons.touch_app_outlined, color: Colors.white70, size: 22),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05);
  }
}
