import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'ui/screens/login_screen.dart';
import 'providers/tire_change_provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/kiosk_exit_gate.dart';

class NimoApp extends StatefulWidget {
  const NimoApp({super.key});

  @override
  State<NimoApp> createState() => _NimoAppState();
}

class _NimoAppState extends State<NimoApp> {
  final AppState _state = AppState();

  /// Kiosk parola penceresi bu anahtar uzerinden acilir; [MaterialApp.builder]
  /// icindeki context Navigator'un ustunde kalir.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TireChangeProvider()),
      ],
      child: AppScope(
        state: _state,
        child: AnimatedBuilder(
          animation: _state,
          builder: (BuildContext context, Widget? child) {
            return MaterialApp(
              title: 'NIMO Bakım',
              debugShowCheckedModeBanner: false,
              navigatorKey: _navigatorKey,
              // Kiosk modunda uygulamadan yalnizca parola ile cikilabilir.
              // Kapi tum sayfalarin uzerinde durur.
              builder: (BuildContext context, Widget? child) => KioskExitGate(
                navigatorKey: _navigatorKey,
                child: child ?? const SizedBox.shrink(),
              ),
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: _state.themeMode,
              locale: const Locale('tr', 'TR'),
              supportedLocales: const <Locale>[Locale('tr', 'TR'), Locale('en', 'US')],
              localizationsDelegates: const <LocalizationsDelegate<Object>>[
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const LoginScreen(),
            );
          },
        ),
      ),
    );
  }
}
