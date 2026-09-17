import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OperationalShell extends StatelessWidget {
  final GoRouterState state;
  final Widget child;

  const OperationalShell({super.key, required this.state, required this.child});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = switch (state.uri.path) {
      '/history' => 1,
      '/settings' => 2,
      _ => 0,
    };
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          context.go(switch (index) {
            1 => '/history',
            2 => '/settings',
            _ => '/',
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_parking_outlined),
            selectedIcon: Icon(Icons.local_parking_rounded),
            label: 'Pátio',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
