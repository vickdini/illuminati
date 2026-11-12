import 'package:flutter/material.dart';

/// The Illuminati logo (same artwork as the app icon).
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/icon/app_icon.png',
    width: size,
    height: size,
    filterQuality: FilterQuality.medium,
    semanticLabel: 'Illuminati',
  );
}
