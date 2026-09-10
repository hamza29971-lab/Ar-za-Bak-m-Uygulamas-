import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'ui/screens/login_screen.dart';
import 'providers/tire_change_provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/kiosk_exit_gate.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';

class NimoApp extends StatefulWidget {
  const NimoApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<NimoApp> createState() => _NimoAppState();
}

class _NimoAppState extends State<NimoApp> {
  final AppState _state = AppState();
  Timer? _updateTimer;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkForUpdate();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_isCheckingUpdate) return;
    
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return;
    }

    _isCheckingUpdate = true;
    try {
      final result = await UpdateService.checkUpdate();
      if (result.available) {
        final context = NimoApp.navigatorKey.currentState?.context;
        if (context != null && context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => UpdateDialog(remoteBuildNumber: result.remoteBuild),
          );
        }
      }
    } catch (_) {
      // Sessizce geç
    } finally {
      if (mounted) {
        _isCheckingUpdate = false;
      }
    }
  }

  // Tek navigatorKey: OTA güncelleme diyaloğu ve Kiosk kapısı için ortaklaşa kullanılır.
  @override
  void dispose() {
    _updateTimer?.cancel();
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
              navigatorKey: NimoApp.navigatorKey,
              title: 'NIMO Bakım',
              debugShowCheckedModeBanner: false,
              // Kiosk modunda uygulamadan yalnizca parola ile cikilabilir.
              // Kapi tum sayfalarin uzerinde durur.
              builder: (BuildContext context, Widget? child) => KioskExitGate(
                navigatorKey: NimoApp.navigatorKey,
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
