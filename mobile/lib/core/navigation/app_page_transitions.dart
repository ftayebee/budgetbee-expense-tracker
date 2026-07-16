import 'package:flutter/material.dart';

enum AppTransitionStyle { forward, authentication, modal, tab }

class AppPageTransitions {
  AppPageTransitions._();

  static Route<T> route<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    AppTransitionStyle style = AppTransitionStyle.forward,
    Color? transitionBackgroundColor,
  }) {
    final duration = style == AppTransitionStyle.tab
        ? Duration.zero
        : const Duration(milliseconds: 260);
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (duration == Duration.zero ||
            MediaQuery.disableAnimationsOf(context)) {
          return child;
        }
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final fade = FadeTransition(opacity: curved, child: child);
        final transitioned = switch (style) {
          AppTransitionStyle.authentication => fade,
          AppTransitionStyle.modal => SlideTransition(
            position: Tween(
              begin: const Offset(0, .04),
              end: Offset.zero,
            ).animate(curved),
            child: fade,
          ),
          AppTransitionStyle.forward => SlideTransition(
            position: Tween(
              begin: const Offset(.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: fade,
          ),
          AppTransitionStyle.tab => child,
        };
        if (transitionBackgroundColor != null) {
          return ColoredBox(
            color: transitionBackgroundColor,
            child: transitioned,
          );
        }
        return transitioned;
      },
    );
  }
}
