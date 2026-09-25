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

  /// Kurulu uygulamanin versionCode'u (pubspec'teki `+N`). OTA'daki
  /// `version.json` `build_number` ile karsilastirilir. Android disinda null.
  Future<int?> installedVersionCode() async {
    if (!_supported) return null;
    try {
      return await _channel.invokeMethod<int>('installedVersionCode');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Indirilen APK'yi sistem yukleyici ekranini acmadan kurar (device owner
  /// sessiz kurulum). Sonuc asenkron gelir: basariliysa uygulama yeniden
  /// baslar, basarisizsa [consumeInstallError] mesaji dondurur.
  ///
  /// Kurulum baslatilamazsa hata mesajini, baslatildiysa null doner.
  Future<String?> installUpdate(String apkPath) async {
    if (!_supported) return 'Güncelleme yalnızca Android tablette kurulabilir.';
    try {
      await _channel.invokeMethod<bool>(
        'installUpdate',
        <String, Object?>{'path': apkPath},
      );
      return null;
    } on PlatformException catch (e) {
      return 'Kurulum başlatılamadı: ${e.message ?? e.code}';
    } on MissingPluginException {
      return 'Kurulum bu cihazda desteklenmiyor.';
    }
  }

  /// Son basarisiz kurulumun mesaji (bir kez okunur).
  Future<String?> consumeInstallError() async {
    if (!_supported) return null;
    try {
      return await _channel.invokeMethod<String>('consumeInstallError');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
