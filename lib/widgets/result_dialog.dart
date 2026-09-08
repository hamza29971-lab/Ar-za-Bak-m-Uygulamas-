import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

/// İşlem sonucu penceresi (ör. "Takviye Kaydedildi").
///
/// "Geçmiş" penceresindeki kayıt detayıyla (bkz. [notifications_dialog.dart])
/// aynı düzen: üstte renkli simge + başlık + alt bilgi, altında etiket/değer
/// satırlarından oluşan kart.
///
/// [details] etiket → değer sırasıyla listelenir. [note] verilirse ayrı bir
/// "Açıklama" kartında gösterilir.
Future<void> showResultDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
  Map<String, String> details = const <String, String>{},
  String? note,
  IconData icon = Icons.check_circle,
  Color? accent,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (BuildContext context) => _ResultDialog(
      title: title,
      subtitle: subtitle,
      details: details,
      note: note,
      icon: icon,
      accent: accent,
    ),
  );
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.title,
    required this.subtitle,
    required this.details,
    required this.note,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String? subtitle;
  final Map<String, String> details;
  final String? note;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color tone = accent == null ? context.brandColor : context.accent(accent!);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 780),
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
                      color: tone.withValues(alpha: context.isDark ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: tone, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                              fontSize: 27, fontWeight: FontWeight.w700),
                        ),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                                fontSize: 17, color: context.mutedColor),
                          ),
                        ],
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (details.isNotEmpty) ...<Widget>[
                      const _SubTitle(text: 'İşlem ayrıntıları'),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            for (final MapEntry<String, String> e
                                in details.entries)
                              InfoLine(
                                label: e.key,
                                value: e.value.isEmpty ? '-' : e.value,
                                labelWidth: 250,
                                labelSize: 16,
                                valueSize: 18,
                                verticalPadding: 8,
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (note != null) ...<Widget>[
                      if (details.isNotEmpty) const SizedBox(height: 22),
                      const _SubTitle(text: 'Açıklama'),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Text(note!,
                            style: const TextStyle(fontSize: 17, height: 1.5)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: context.borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.accentFill(
                          accent ?? const Color(0xFF198754)),
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

/// Bölüm başlığı; "Geçmiş" detay penceresindekiyle aynı.
class _SubTitle extends StatelessWidget {
  const _SubTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 14,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
        color: context.mutedColor,
      ),
    );
  }
}
