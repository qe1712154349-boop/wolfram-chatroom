import 'package:flutter/material.dart';

class ImagePlaceholder extends StatelessWidget {
  final double size;
  final Color color;
  final IconData? icon;
  final String? text;

  const ImagePlaceholder({
    super.key,
    this.size = 40,
    this.color = const Color(0xFFFF5A7E),
    this.icon = Icons.person,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: text != null
            ? Text(
                text!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Icon(
                icon,
                color: Colors.white,
                size: size * 0.6,
              ),
      ),
    );
  }
}