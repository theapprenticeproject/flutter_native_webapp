import 'package:flutter/material.dart';

class CardDeckWrapper extends StatelessWidget {
  final Widget child;

  const CardDeckWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0E1EA),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(14, -14),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 0,
            spreadRadius: -1,
            offset: const Offset(14, -14),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9DAE4), width: 1),
        ),
        child: child,
      ),
    );
  }
}
