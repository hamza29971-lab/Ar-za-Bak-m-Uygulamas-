import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Kiosk parolasinin sonucu.
enum KioskUnlockResult {
  /// 482910: Ayarlar acildi. Uygulama silme ve fabrika ayarlari kapali kalir.
  settings,

  /// 905174: cihaz sahipligi birakildi. Uygulama artik silinebilir.
  released,

  /// Parola yanlis.
  invalid,

  /// Tablet kiosk modunda degil (device owner atanmamis).
  noOwner,

  /// Islem denendi ama Android reddetti; ayrinti icin logcat.
  failed,
}

/// Tabletin kiosk (device-owner) durumu.
@immutable
class KioskStatus {
  const KioskStatus({
    required this.deviceOwner,
    required this.lockTaskPermitted,
    required this.locked,
    required this.settingsMode,
  });

  const KioskStatus.unavailable()
      : deviceOwner = false,
        lockTaskPermitted = false,
        locked = false,
        settingsMode = false;

  /// Uygulama tabletin cihaz sahibi mi?
  final bool deviceOwner;

  /// Ekran kilidi izin listesinde mi?
  final bool lockTaskPermitted;

  /// Su anda gercek LOCKED modunda mi? (Kullanicinin kendi baslattigi
  /// PINNED ekran sabitleme guvenli kiosk sayilmaz ve burada false doner.)
  final bool locked;

  /// 482910 ile Ayarlar'a cikilmis durumda mi?
  final bool settingsMode;

  /// Tablet sahaya verilebilir durumda mi?
  bool get healthy => deviceOwner && lockTaskPermitted && locked;
}

/// Android tarafindaki kiosk politikasina koprü.
///
/// Parolalar bilerek Dart tarafinda TUTULMAZ; dogrulama Kotlin'de
/// (MainActivity) yapilir.
class KioskService {
  KioskService._();

  static final KioskService instance = KioskService._();

  static const MethodChannel _channel =
      MethodChannel('com.nimo.nimo_arizabakim/kiosk');

  /// Kiosk yalnizca Android tablette anlamlidir; Windows'ta calisirken
  /// tum cagrilar sessizce bos doner.
  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<KioskStatus> status() async {
    if (!_supported) return const KioskStatus.unavailable();
    try {
      final Map<Object?, Object?>? raw =
          await _channel.invokeMethod<Map<Object?, Object?>>('status');
      if (raw == null) return const KioskStatus.unavailable();
      return KioskStatus(
        deviceOwner: raw['deviceOwner'] == true,
        lockTaskPermitted: raw['lockTaskPermitted'] == true,
        locked: raw['locked'] == true,
        settingsMode: raw['settingsMode'] == true,
      );
    } on PlatformException {
      return const KioskStatus.unavailable();
    } on MissingPluginException {
      return const KioskStatus.unavailable();
    }
  }

  /// Girilen parolayi Android tarafina dogrulatir ve karsiligindaki
  /// islemi yaptirir.
  Future<KioskUnlockResult> unlock(String password) async {
    if (!_supported) return KioskUnlockResult.noOwner;
    try {
      final String? code = await _channel.invokeMethod<String>(
        'unlock',
        <String, Object?>{'password': password},
      );
      switch (code) {
        case 'settings':
          return KioskUnlockResult.settings;
        case 'released':
          return KioskUnlockResult.released;
        case 'no_owner':
          return KioskUnlockResult.noOwner;
        case 'failed':
          return KioskUnlockResult.failed;
        default:
          return KioskUnlockResult.invalid;
      }
    } on PlatformException {
      return KioskUnlockResult.failed;
    } on MissingPluginException {
      return KioskUnlockResult.noOwner;
    }
  }
}
