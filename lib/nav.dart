import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/vehicle.dart';
import 'screens/check_in_page.dart';
import 'screens/history_page.dart';
import 'screens/home_page.dart';
import 'screens/settings_page.dart';
import 'screens/ticket_details_page.dart';
import 'widgets/operational_shell.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return OperationalShell(state: state, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: AppRoutes.history,
            name: 'history',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HistoryPage()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.checkIn,
        name: 'check-in',
        pageBuilder: (context, state) {
          return MaterialPage(
            child: CheckInPage(vehicleToEdit: state.extra as Vehicle?),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.ticketDetails,
        name: 'ticket-details',
        pageBuilder: (context, state) {
          return MaterialPage(
            child: TicketDetailsPage(ticketId: state.pathParameters['id']!),
          );
        },
      ),
    ],
  );
}

class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const checkIn = '/check-in';
  static const ticketDetails = '/ticket/:id';
  static const history = '/history';
  static const settings = '/settings';
}
