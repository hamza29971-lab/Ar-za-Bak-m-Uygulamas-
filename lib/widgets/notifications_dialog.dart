import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import 'common.dart';

/// Zil ikonuna basıldığında açılan "Geçmiş" penceresi.
Future<void> showNotificationsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (BuildContext context) => const _NotificationsDialog(),
  );
}

/// Kayıt türünün simgesi ve rengi (liste ve detay penceresi aynısını kullanır).
({IconData icon, Color color}) _visual(NotificationKind kind) => switch (kind) {
      NotificationKind.tire => (icon: Icons.trip_origin, color: AppColors.tire),
      NotificationKind.oil =>
        (icon: Icons.water_drop_outlined, color: AppColors.oil),
      NotificationKind.form =>
        (icon: Icons.description_outlined, color: AppColors.form),
      NotificationKind.warning =>
        (icon: Icons.warning_amber_rounded, color: AppColors.fault),
      NotificationKind.info => (icon: Icons.info_outline, color: AppColors.brand),
    };

class _NotificationsDialog extends StatefulWidget {
  const _NotificationsDialog();

  @override
  State<_NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends State<_NotificationsDialog> {
  /// Seçili tür süzgeci; `null` iken bütün geçmiş listelenir. Aynı düğmeye
  /// yeniden basmak süzgeci kaldırır.
  NotificationKind? _filter;

  void _toggle(NotificationKind kind) =>
      setState(() => _filter = _filter == kind ? null : kind);

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final List<NotificationItem> all = state.notifications;
    final List<NotificationItem> items = _filter == null
        ? all
        : all
            .where((NotificationItem n) => n.kind == _filter)
            .toList(growable: false);
    final int unread = state.unreadCount;

    final String listLabel = switch (_filter) {
      NotificationKind.tire => 'Lastik geçmişi',
      NotificationKind.oil => 'Yağ geçmişi',
      _ => 'Tüm geçmiş',
    };

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
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
                    child: Icon(Icons.history,
                        color: context.brandColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Geçmiş',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          unread == 0 ? 'Hepsi güncel' : '$unread yeni işlem',
                          style: TextStyle(fontSize: 13, color: context.mutedColor),
                        ),
                      ],
                    ),
                  ),
                  // Tür süzgeçleri
                  _FilterButton(
                    label: 'Lastik',
                    kind: NotificationKind.tire,
                    selected: _filter == NotificationKind.tire,
                    onTap: () => _toggle(NotificationKind.tire),
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    label: 'Yağ',
                    kind: NotificationKind.oil,
                    selected: _filter == NotificationKind.oil,
                    onTap: () => _toggle(NotificationKind.oil),
                  ),
                  const SizedBox(width: 14),
                  IconButton.outlined(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Sayaç satırı
            Container(
              color: context.cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(listLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${items.length} kayıt',
                      style: TextStyle(fontSize: 13, color: context.mutedColor)),
                ],
              ),
            ),
            Divider(height: 1, color: context.borderColor),
            Flexible(
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.inbox_outlined, size: 42, color: context.mutedColor),
                          const SizedBox(height: 14),
                          Text(
                            _filter == null
                                ? 'Henüz geçmiş kaydı yok.'
                                : 'Bu türde geçmiş kaydı yok.',
                            style: TextStyle(color: context.mutedColor, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: context.borderColor),
                      itemBuilder: (BuildContext context, int i) => _NotificationTile(
                        item: items[i],
                        onTap: () => _openDetails(context, state, items[i]),
                      ),
                    ),
            ),
            Divider(height: 1, color: context.borderColor),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton.icon(
                    onPressed: all.isEmpty ? null : state.markAllRead,
                    icon: const Icon(Icons.done_all),
                    label: const Text('Tümünü okundu işaretle'),
                    style: TextButton.styleFrom(foregroundColor: context.brandColor),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: all.isEmpty ? null : state.clearNotifications,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Listeyi temizle'),
                    style: TextButton.styleFrom(foregroundColor: context.mutedColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kayda tıklanınca detay penceresi açılır; kayıt aynı anda okundu sayılır.
  Future<void> _openDetails(
    BuildContext context,
    AppState state,
    NotificationItem item,
  ) async {
    if (!item.read) state.markRead(item);
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => _NotificationDetailsDialog(item: item),
    );
  }
}

/// Başlıktaki "Lastik" / "Yağ" süzgeç düğmesi.
class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final NotificationKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color color}) visual = _visual(kind);
    final Color tone = context.accent(visual.color);

    return selected
        ? FilledButton.icon(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: tone,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: Icon(visual.icon, size: 18),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: tone,
              side: BorderSide(color: context.borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: Icon(visual.icon, size: 18),
            label: Text(label),
          );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color color}) visual = _visual(item.kind);
    final Color color = context.accent(visual.color);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: item.read
            ? Colors.transparent
            : color.withValues(alpha: context.isDark ? 0.08 : 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: context.isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(visual.icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.read ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!item.read) ...<Widget>[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.message,
                      style: TextStyle(fontSize: 13, color: context.mutedColor)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(relativeTime(item.date),
                style: TextStyle(fontSize: 12, color: context.mutedColor)),
            const SizedBox(width: 6),
            // Satırın tıklanabilir olduğunu belli eder.
            Icon(Icons.chevron_right, size: 20, color: context.mutedColor),
          ],
        ),
      ),
    );
  }
}

/// Geçmiş kaydına tıklanınca açılan, yapılan işlemin ayrıntılarını gösteren
/// pencere.
class _NotificationDetailsDialog extends StatelessWidget {
  const _NotificationDetailsDialog({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color color}) visual = _visual(item.kind);
    final Color tone = context.accent(visual.color);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 18),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: context.isDark ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(visual.icon, color: tone, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(item.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${formatDateTime(item.date)} • ${relativeTime(item.date)}',
                          style: TextStyle(fontSize: 13, color: context.mutedColor),
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (item.vehicleCode != null &&
                        item.vehicleCode!.isNotEmpty)
                      InfoLine(
                        label: 'Araç',
                        value: item.vehicleCode!,
                        labelWidth: 180,
                      ),
                    InfoLine(
                      label: 'İşlem tarihi',
                      value: formatDateTime(item.date),
                      labelWidth: 180,
                    ),
                    if (item.details.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 20),
                      _SubTitle(text: 'İşlem ayrıntıları'),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            for (final MapEntry<String, String> e
                                in item.details.entries)
                              InfoLine(
                                label: e.key,
                                value: e.value.isEmpty ? '-' : e.value,
                                labelWidth: 180,
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _SubTitle(text: 'Özet'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Text(item.message, style: const TextStyle(height: 1.5)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubTitle extends StatelessWidget {
  const _SubTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
        color: context.mutedColor,
      ),
    );
  }
}
