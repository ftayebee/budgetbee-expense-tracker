import 'package:flutter/widgets.dart';

class MainTabScope extends InheritedWidget {
  const MainTabScope({
    super.key,
    required this.activeIndex,
    required this.onSelect,
    required super.child,
  });

  final int activeIndex;
  final ValueChanged<int> onSelect;

  static MainTabScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainTabScope>();

  @override
  bool updateShouldNotify(MainTabScope oldWidget) =>
      activeIndex != oldWidget.activeIndex;
}
