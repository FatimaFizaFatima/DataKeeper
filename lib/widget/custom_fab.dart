import 'package:flutter/material.dart';

class CustomFAB extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final String heroTag;

  const CustomFAB({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        elevation: 4,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
