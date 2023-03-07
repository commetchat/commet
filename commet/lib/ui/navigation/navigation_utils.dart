import 'package:flutter/material.dart';

class NavigationUtils {
  static void navigateTo(BuildContext context, Widget page) {
    Navigator.push(
        context,
        PageRouteBuilder(
            pageBuilder: (_, __, ___) => page,
            transitionDuration: Duration(milliseconds: 500),
            transitionsBuilder: (_, animation, __, child) => SlideTransition(
                child: child,
                position: Tween<Offset>(
                  begin: const Offset(0, 1.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)))));
  }
}
