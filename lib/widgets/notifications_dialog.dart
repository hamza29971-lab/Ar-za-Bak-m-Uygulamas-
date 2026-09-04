import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';

/// Zil ikonuna basıldığında açılan "Bildirimler" penceresi.
Future<void> showNotificationsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (BuildContext context) => const _NotificationsDialog(),
  );
}

class _NotificationsDialog extends StatelessWidget {
  const _NotificationsDialog();

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final List<NotificationItem> items = state.notifications;
    final int unread = state.unreadCount;

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
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history,
                        color: AppColors.brand, size: 24),
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
                  const Text('Tüm geçmiş',
                      style: TextStyle(fontWeight: FontWeight.w600)),
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
                          Text('Henüz geçmiş kaydı yok.',
                              style: TextStyle(color: context.mutedColor, fontSize: 15)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: context.borderColor),
                      itemBuilder: (BuildContext context, int i) =>
                          _NotificationTile(item: items[i]),
                    ),
            ),
            Divider(height: 1, color: context.borderColor),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton.icon(
                    onPressed: items.isEmpty ? null : state.markAllRead,
                    icon: const Icon(Icons.done_all),
                    label: const Text('Tümünü okundu işaretle'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.brand),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: items.isEmpty ? null : state.clearNotifications,
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
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (item.kind) {
      NotificationKind.tire => (Icons.trip_origin, AppColors.tire),
      NotificationKind.oil => (Icons.water_drop_outlined, AppColors.oil),
      NotificationKind.form => (Icons.description_outlined, AppColors.form),
      NotificationKind.warning => (Icons.warning_amber_rounded, AppColors.fault),
      NotificationKind.info => (Icons.info_outline, AppColors.brand),
    };

    return Container(
      color: item.read ? Colors.transparent : color.withValues(alpha: 0.04),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
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
        ],
      ),
    );
  }
}
