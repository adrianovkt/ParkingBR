import 'package:flutter/material.dart';
import 'package:parking_br/nav.dart';
import 'package:parking_br/providers/parking_provider.dart';
import 'package:parking_br/providers/settings_provider.dart';
import 'package:parking_br/services/log_service.dart';
import 'package:parking_br/theme.dart';
import 'package:provider/provider.dart';

void main() {
  // Initialize log capture early
  LogService.I.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ParkingProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp.router(
          title: 'Parking BR',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: settings.themeMode,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
