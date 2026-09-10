// lib/widgets/update_dialog.dart
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';

class UpdateDialog extends StatefulWidget {
  final int remoteBuildNumber;
  const UpdateDialog({super.key, required this.remoteBuildNumber});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';

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

      if (mounted) {
        setState(() => _statusText = 'Kurulum başlatılıyor...');
        final result = await OpenFile.open(
          file.path,
          type: 'application/vnd.android.package-archive',
        );
        
        if (mounted) {
          if (result.type == ResultType.done) {
            Navigator.of(context).pop();
          } else {
            setState(() {
              _isDownloading = false;
              _statusText = 'Kurulum hatası: ${result.message}';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Hata: $e';
        });
      }
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
