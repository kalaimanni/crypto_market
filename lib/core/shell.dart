import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.show_chart_rounded), label: 'Markets'),
            NavigationDestination(icon: Icon(Icons.insights_rounded), label: 'Stats'),
            NavigationDestination(icon: Icon(Icons.star_rounded), label: 'Watchlist'),
          ],
        ),
      );
}
