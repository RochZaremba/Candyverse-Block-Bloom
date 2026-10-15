import 'package:flutter/material.dart';

import '../../settings/settings_model.dart';

/// Opaque scenes retain their painted background throughout route changes.
class CandyPageTransitionsBuilder extends PageTransitionsBuilder {
  const CandyPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (SettingsScope.reducedMotionOf(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.045, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: .82, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }
}
