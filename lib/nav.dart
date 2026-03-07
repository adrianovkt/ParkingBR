import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:parking_br/screens/check_in_page.dart';
import 'package:parking_br/screens/home_page.dart';
import 'package:parking_br/screens/settings_page.dart';
import 'package:parking_br/screens/ticket_details_page.dart';
import 'package:parking_br/screens/wallet_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HomePage()),
      ),
      GoRoute(
        path: AppRoutes.checkIn,
        name: 'check-in',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: CheckInPage()),
      ),
      GoRoute(
        path: AppRoutes.ticketDetails,
        name: 'ticket-details',
        pageBuilder: (context, state) {
          final ticketId = state.pathParameters['id']!;
          return NoTransitionPage(child: TicketDetailsPage(ticketId: ticketId));
        },
      ),
      GoRoute(
        path: AppRoutes.wallet,
        name: 'wallet',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: WalletPage()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SettingsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: animation.drive(tween),
                child: child,
              ),
            );
          },
        ),
      ),
    ],
  );
}

class AppRoutes {
  AppRoutes._();
  static const String home = '/';
  static const String checkIn = '/check-in';
  static const String ticketDetails = '/ticket/:id';
  static const String wallet = '/wallet';
  static const String settings = '/settings';
}
