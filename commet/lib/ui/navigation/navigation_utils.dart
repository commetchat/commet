import 'package:flutter/material.dart';

class NavigationUtils {
  static void navigateTo(BuildContext context, Widget page) {
    Navigator.push(
        context,
        PageRouteBuilder(
            pageBuilder: (_, __, ___) => page,
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, animation, __, child) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child)));
  }
}
