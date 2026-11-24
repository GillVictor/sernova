import 'package:flutter/material.dart';

/// Placeholder logo (handshake). Replace with the real asset when provided.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 40, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.handshake_outlined, size: size, color: color);
}
