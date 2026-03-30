import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double scale;
  final bool isLight;
  final bool showTitle;
  final bool isCompact;
  
  const BrandLogo({
    super.key, 
    this.scale = 1.0, 
    this.isLight = false,
    this.showTitle = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final String assetPath = showTitle 
        ? 'assets/images/logo/NAGA-title.png' 
        : 'assets/images/logo/NAGA.png';

    if (isCompact) {
      return Image.asset(
        assetPath,
        height: 34, // Matches the previous manual height
        fit: BoxFit.contain,
        color: isLight ? Colors.white : null,
      );
    }

    return Transform.scale(
      scale: scale,
      child: Image.asset(
        assetPath,
        width: showTitle ? 180 : 100,
        fit: BoxFit.contain,
        color: isLight ? Colors.white : null,
      ),
    );
  }
}
