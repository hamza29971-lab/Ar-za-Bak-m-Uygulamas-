import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';

/// "Gönder" onay penceresinin sonucu.
enum PendingSendChoice { send, discard }

/// Lastik Değişimi ve Yağ Takviyesi ekranlarında "Gönder" butonuna
/// basıldığında açılan ortak onay penceresi. Bekleyen işlemler, "Geçmiş"
/// penceresindeki (bkz. [notifications_dialog.dart]) kayıt satırlarıyla aynı
/// stilde listelenir.
///
/// Döndürülen değer: [PendingSendChoice.send] gönder, [PendingSendChoice.discard]
/// listeyi boşalt, `null` ise "Geri Dön" ile kapatıldı.
Future<PendingSendChoice?> showPendingSendDialog({
  required BuildContext context,
  required List<PendingOperation> pending,
}) {
  return showDialog<PendingSendChoice>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (BuildContext context) => _PendingSendDialog(pending: pending),
  );
}

/// Kayıt türünün simgesi ve rengi.
({IconData icon, Color color}) _visual(PendingKind kind) => switch (kind) {
      PendingKind.tire => (icon: Icons.trip_origin, color: AppColors.tire),
      PendingKind.oil =>
        (icon: Icons.water_drop_outlined, color: AppColors.oil),
    };

class _PendingSendDialog extends StatelessWidget {
  const _PendingSendDialog({required this.pending});

  final List<PendingOperation> pending;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 18),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: context.brandSoftColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.send_rounded,
                        color: context.brandColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Emin misiniz?',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${pending.length} işlem gönderilecek',
                          style:
                              TextStyle(fontSize: 13, color: context.mutedColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.borderColor),
            // Gönderilecek işlemlerin listesi
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: pending.length,
                separatorBuilder: (BuildContext context, int _) =>
                    Divider(height: 1, color: context.borderColor),
                itemBuilder: (BuildContext context, int i) =>
                    _PendingTile(item: pending[i]),
              ),
            ),
            Divider(height: 1, color: context.borderColor),
            // Alt eylemler
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(PendingSendChoice.discard),
                    style: TextButton.styleFrom(
                        foregroundColor: context.accent(AppColors.emergency)),
                    child: const Text('İptal Et'),
                  ),
                  Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Geri Dön',
                            style: TextStyle(color: context.mutedColor)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.of(context)
                            .pop(PendingSendChoice.send),
                        style: FilledButton.styleFrom(
                            backgroundColor:
                                context.accentFill(const Color(0xFF198754))),
                        child: const Text('Evet, Gönder'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Geçmiş" penceresindeki kayıt satırıyla aynı düzende: soldaki renkli
/// simge, araç kodu ve işlem açıklaması, sağda göreli zaman.
class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.item});

  final PendingOperation item;

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color color}) visual = _visual(item.kind);
    final Color color = context.accent(visual.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: context.isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(visual.icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.vehicleCode,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(item.label,
                    style: TextStyle(fontSize: 13, color: context.mutedColor)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(relativeTime(item.date),
              style: TextStyle(fontSize: 12, color: context.mutedColor)),
        ],
      ),
    );
  }
}
