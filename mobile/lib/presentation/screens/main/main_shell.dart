import 'package:flutter/material.dart';

import '../../../core/navigation/main_tab_scope.dart';
import '../all_screens.dart';
import '../settings/safe_settings_screens.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex.clamp(0, 3);

  static const _tabs = <Widget>[
    DashboardScreen(),
    TransactionsScreen(),
    ReportsScreen(),
    SafeSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) => MainTabScope(
    activeIndex: _index,
    onSelect: (index) {
      if (index != _index) setState(() => _index = index);
    },
    child: IndexedStack(index: _index, children: _tabs),
  );
}
