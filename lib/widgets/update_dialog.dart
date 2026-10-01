// lib/widgets/update_dialog.dart
import 'package:flutter/material.dart';
import '../services/kiosk_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';

class UpdateDialog extends StatefulWidget {
  final int remoteBuildNumber;
  const UpdateDialog({super.key, required this.remoteBuildNumber});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  /// Kurulum sonucunun bekleneceği en uzun süre. Düşük donanımlı tablette
  /// ~85 MB'lık APK'nın kurulumu (derleme dahil) 2 dakikayı aşabiliyor.
  static const int _installWaitSeconds = 300;

  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';

  /// Tabletin kiosk durumu; sessiz kurulum yalnızca cihaz sahibinde çalışır.
  KioskStatus? _kiosk;

  @override
  void initState() {
    super.initState();
    KioskService.instance.status().then((KioskStatus s) {
      if (mounted) setState(() => _kiosk = s);
    });
  }

  String get _ownerText => switch (_kiosk?.deviceOwner) {
        true => 'cihaz sahibi: evet',
        false => 'cihaz sahibi: HAYIR',
        null => 'cihaz sahibi: bilinmiyor',
      };

  /// Hata gösterilir ve düğmeler geri gelir; güncelleme "kuruldu" sayılmadığı
  /// için bir sonraki kontrolde yeniden önerilir.
  void _fail(String message) {
    setState(() {
      _isDownloading = false;
      _statusText = 'Hata: $message';
    });
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _statusText = 'İndiriliyor...';
    });

    try {
      final file = await UpdateService.downloadApk(
        widget.remoteBuildNumber,
        (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _statusText =
                  'İndiriliyor... %${(progress * 100).toStringAsFixed(0)}';
            });
          }
        },
      );

      if (!mounted) return;
      setState(() => _statusText = 'Kurulum başlatılıyor...');

      // Sistem yükleyici ekranı kiosk kilidinde açılamadığı için kurulum
      // Android tarafında sessizce yapılır (device owner). Play Protect
      // imzayı tanımazsa Android kendi onay ekranını açabilir; bu durumda
      // MainActivity kilidi geçici kaldırıp ekranı gösterir, kullanıcı bir
      // kez dokunur.
      final String? startError =
          await KioskService.instance.installUpdate(file.path);
      if (!mounted) return;
      if (startError != null) {
        _fail(startError);
        return;
      }

      // Başarılı kurulumda uygulama süreci sonlandırılıp yeniden açılır ve bu
      // döngü hiç bitmez. Bitiyorsa kurulum başarısız olmuştur.
      for (int i = 0; i < _installWaitSeconds; i++) {
        setState(() => _statusText =
            'Güncelleme kuruluyor (${i}s). Uygulama birazdan kendiliğinden yeniden açılacak.');
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        final String? error = await KioskService.instance.consumeInstallError();
        if (error != null) {
          _fail(error);
          return;
        }
      }
      if (mounted) {
        _fail('Kurulum $_installWaitSeconds saniyede tamamlanmadı ($_ownerText). '
            'Tablet cihaz sahibi değilse kiosk kurulumu yeniden yapılmalı.');
      }
    } catch (e) {
      if (mounted) _fail('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update, color: context.brandColor, size: 28),
          const SizedBox(width: 12),
          Text(
            'Yeni Güncelleme Mevcut',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.text.titleLarge?.color),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yeni sürüm mevcut (Build ${widget.remoteBuildNumber}).\nGüncellemek ister misiniz?',
              style: TextStyle(fontSize: 16, color: context.text.bodyMedium?.color),
            ),
            if (_kiosk != null && !_kiosk!.deviceOwner) ...[
              const SizedBox(height: 12),
              Text(
                'Uyarı: Uygulama bu tablette cihaz sahibi değil. Sessiz kurulum '
                'yapılamaz; kiosk kurulumu script ile yeniden yapılmalı.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            if (_isDownloading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: context.mutedColor.withValues(alpha: 0.2),
                color: context.brandColor,
                minHeight: 8,
              ),
            ],
            if (_statusText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _statusText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _statusText.toLowerCase().contains('hata')
                      ? Theme.of(context).colorScheme.error
                      : context.text.bodyMedium?.color,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: _isDownloading
          ? null
          : [
              TextButton(
                onPressed: () {
                  UpdateService.ignoreBuild(widget.remoteBuildNumber);
                  Navigator.of(context).pop();
                },
                child: Text('Şimdi Değil',
                    style: TextStyle(color: context.mutedColor)),
              ),
              ElevatedButton.icon(
                onPressed: _startDownload,
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('Güncelle',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.brandColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
    );
  }
}
