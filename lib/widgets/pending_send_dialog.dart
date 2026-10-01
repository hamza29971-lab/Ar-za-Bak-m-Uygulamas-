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
  List<String> unmatchedVehicles = const <String>[],
}) {
  return showDialog<PendingSendChoice>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (BuildContext context) => _PendingSendDialog(
      pending: pending,
      unmatchedVehicles: unmatchedVehicles,
    ),
  );
}

/// Gönderim tamamlandıktan sonra açılan sonuç penceresi. Onay penceresiyle
/// aynı düzen ve satır stili kullanılır; farkı yeşil onay simgesi ve tek
/// "Tamam" butonudur.
Future<void> showPendingSentDialog({
  required BuildContext context,
  required List<PendingOperation> sent,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (BuildContext context) => _PendingSentDialog(sent: sent),
  );
}

/// Kayıt türünün simgesi ve rengi.
({IconData icon, Color color}) _visual(PendingKind kind) => switch (kind) {
      PendingKind.tire => (icon: Icons.trip_origin, color: AppColors.tire),
      PendingKind.oil =>
        (icon: Icons.water_drop_outlined, color: AppColors.oil),
    };

class _PendingSendDialog extends StatelessWidget {
  const _PendingSendDialog({
    required this.pending,
    this.unmatchedVehicles = const <String>[],
  });

  final List<PendingOperation> pending;

  /// Sunucuyla eşleşmemiş araç kodları. Bu kayıtlar panele araçsız
  /// düşeceği için kullanıcı gönderimden ÖNCE uyarılır.
  final List<String> unmatchedVehicles;

  /// Gönderilecek işlemler arasında eşleşmeyen araç var mı?
  List<String> get _affected {
    final Set<String> codes =
        pending.map((PendingOperation p) => p.vehicleCode).toSet();
    return <String>[
      for (final String code in unmatchedVehicles)
        if (codes.contains(code)) code,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 820),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 30, 24, 26),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: context.brandSoftColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.send_rounded,
                        color: context.brandColor, size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Emin misiniz?',
                            style: TextStyle(
                                fontSize: 27, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          '${pending.length} işlem gönderilecek',
                          style:
                              TextStyle(fontSize: 17, color: context.mutedColor),
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
            if (_affected.isNotEmpty) _warning(context, _affected),
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
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(PendingSendChoice.discard),
                    style: TextButton.styleFrom(
                      foregroundColor: context.accent(AppColors.emergency),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                    ),
                    child:
                        const Text('İptal Et', style: TextStyle(fontSize: 17)),
                  ),
                  Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 20),
                        ),
                        child: Text('Geri Dön',
                            style: TextStyle(
                                fontSize: 17, color: context.mutedColor)),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () => Navigator.of(context)
                            .pop(PendingSendChoice.send),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              context.accentFill(const Color(0xFF198754)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 38, vertical: 20),
                        ),
                        child: const Text('Evet, Gönder',
                            style: TextStyle(fontSize: 17)),
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

/// Araç sunucuyla eşleşmediğinde gösterilen uyarı şeridi.
Widget _warning(BuildContext context, List<String> codes) {
  final Color tone = context.accent(AppColors.fault);
  return Container(
    width: double.infinity,
    color: tone.withValues(alpha: context.isDark ? 0.16 : 0.10),
    padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.warning_amber_rounded, color: tone, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                codes.length == 1
                    ? '${codes.first} sunucuyla eşleşmedi'
                    : '${codes.length} araç sunucuyla eşleşmedi',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: tone),
              ),
              const SizedBox(height: 4),
              Text(
                'Bu araçlara ait kayıtlar panele araç bilgisi olmadan '
                'düşecek: ${codes.join(', ')}. Yine de gönderebilirsiniz, '
                'ancak yetkiliye bildirmeniz önerilir.',
                style: TextStyle(
                    fontSize: 14, height: 1.4, color: context.mutedColor),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Gönderim tamamlandığında gösterilen sonuç penceresi.
class _PendingSentDialog extends StatelessWidget {
  const _PendingSentDialog({required this.sent});

  final List<PendingOperation> sent;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 820),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 30, 24, 26),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: context.brandSoftColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.check_circle,
                        color: context.brandColor, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('İşlemler Gönderildi',
                            style: TextStyle(
                                fontSize: 27, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          '${sent.length} işlem gönderildi • '
                          '${formatDateTime(DateTime.now())}',
                          style:
                              TextStyle(fontSize: 17, color: context.mutedColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.borderColor),
            // Gönderilen işlemler
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: sent.length,
                separatorBuilder: (BuildContext context, int _) =>
                    Divider(height: 1, color: context.borderColor),
                itemBuilder: (BuildContext context, int i) =>
                    _PendingTile(item: sent[i]),
              ),
            ),
            Divider(height: 1, color: context.borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FilledButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          context.accentFill(const Color(0xFF198754)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 38, vertical: 20),
                    ),
                    child: const Text('Tamam',
                        style: TextStyle(fontSize: 17)),
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: context.isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(visual.icon, size: 28, color: color),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.vehicleCode,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                Text(item.label,
                    style: TextStyle(
                        fontSize: 17, height: 1.4, color: context.mutedColor)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(relativeTime(item.date),
                  style: TextStyle(fontSize: 15, color: context.mutedColor)),
              const SizedBox(height: 4),
              Text(formatDateTime(item.date),
                  style: TextStyle(fontSize: 14, color: context.mutedColor)),
            ],
          ),
        ],
      ),
    );
  }
}
