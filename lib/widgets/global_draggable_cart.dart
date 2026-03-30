import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../screens/cart/cart_screen.dart';
import '../../theme/app_colors.dart';
import '../../main.dart'; 

final ValueNotifier<bool> hideGlobalCart = ValueNotifier(false);

class GlobalDraggableCart extends StatefulWidget {
  const GlobalDraggableCart({super.key});

  @override
  State<GlobalDraggableCart> createState() => _GlobalDraggableCartState();
}

class _GlobalDraggableCartState extends State<GlobalDraggableCart> {
  Offset _position = const Offset(20, 100);
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final size = MediaQuery.of(context).size;
      _position = Offset(
        math.max(0.0, size.width - 80.0),
        math.max(0.0, size.height - 150.0), // Above bottom nav roughly
      );
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: hideGlobalCart,
      builder: (context, hidden, child) {
        if (hidden) return const SizedBox.shrink();

        final size = MediaQuery.of(context).size;
        final maxDx = math.max(0.0, size.width - 60.0);
        final maxDy = math.max(0.0, size.height - 60.0);
        
        // Safety clamp in case of rotation/resize
        _position = Offset(
          _position.dx.clamp(0.0, maxDx),
          _position.dy.clamp(0.0, maxDy),
        );

        return Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position += details.delta;
                _position = Offset(
                  _position.dx.clamp(0.0, maxDx),
                  _position.dy.clamp(0.0, maxDy),
                );
              });
            },
            onTap: () {
              // Use the global navigator key to push over the main navigator
              if (navigatorKey.currentState != null) {
                navigatorKey.currentState!.push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              }
            },
            child: Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                final cartItemCount = cartProvider.itemCount;
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryStart,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryStart.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white, size: 28),
                      if (cartItemCount > 0)
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$cartItemCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

