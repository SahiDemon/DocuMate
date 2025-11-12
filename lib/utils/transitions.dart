import 'package:flutter/material.dart';

/// Subtle, non-gimmicky page transition: small slide up + scale with easeOutBack
PageRouteBuilder<T> subtleScaleSlideRoute<T>({required Widget page}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 550),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );

      // Slide from bottom
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(curved);

      // Slight scale up
      final scaleAnimation =
          Tween<double>(begin: 0.98, end: 1.0).animate(curved);

      return SlideTransition(
        position: offsetAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      );
    },
  );
}
