import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import 'common.dart';

/// İşlem türüne göre farklı detay gösteren pencere.
Future<void> showActivityDetails(BuildContext context, ActivityRecord activity) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => _ActivityDialog(activity: activity),
  );
}

/// İşlem türünün rengi ve simgesi (liste ve pencere aynı görseli kullanır).
({IconData icon, Color color}) activityVisual(ActivityType type) => switch (type) {
      ActivityType.tireChange => (icon: Icons.trip_origin, color: AppColors.tire),
      ActivityType.oilRefill => (icon: Icons.water_drop_outlined, color: AppColors.oil),
      ActivityType.serviceReport =>
        (icon: Icons.description_outlined, color: AppColors.form),
    };

class _ActivityDialog extends StatelessWidget {
  const _ActivityDialog({required this.activity});

  final ActivityRecord activity;

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color color}) visual = activityVisual(activity.type);
    final Color tone = context.accent(visual.color);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 620),
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
                        Text(activity.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${formatDateTime(activity.date)} • ${relativeTime(activity.date)}',
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
                child: switch (activity) {
                  final TireChangeActivity a => _TireDetails(activity: a),
                  final OilRefillActivity a => _OilDetails(activity: a),
                  final ServiceReportActivity a => _ReportDetails(activity: a),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ lastik değişimi

class _TireDetails extends StatelessWidget {
  const _TireDetails({required this.activity});

  final TireChangeActivity activity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InfoLine(label: 'Aracın adı', value: activity.vehicleCode, labelWidth: 180),
        InfoLine(
          label: 'Değişen lastik sayısı',
          value: '${activity.tires.length}',
          labelWidth: 180,
        ),
        InfoLine(
          label: 'İşlem tarihi',
          value: formatDateTime(activity.date),
          labelWidth: 180,
        ),
        const SizedBox(height: 20),
        _SubTitle(text: 'Değişen lastikler'),
        const SizedBox(height: 10),
        for (final TireChangeDetail tire in activity.tires) ...<Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.trip_origin, size: 18, color: context.accent(AppColors.tire)),
                    const SizedBox(width: 10),
                    Text(tire.tireId,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    Text(tire.position,
                        style: TextStyle(fontSize: 13, color: context.mutedColor)),
                  ],
                ),
                const SizedBox(height: 10),
                InfoLine(label: 'Seri numarası', value: tire.serialNo, labelWidth: 160),
                InfoLine(
                  label: 'Değişim tarihi',
                  value: formatDateTime(tire.changedAt),
                  labelWidth: 160,
                ),
                InfoLine(
                  label: 'Son kontrol tarihi',
                  value: formatDateTime(tire.lastCheckDate),
                  labelWidth: 160,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// -------------------------------------------------------------- yağ takviyesi

class _OilDetails extends StatelessWidget {
  const _OilDetails({required this.activity});

  final OilRefillActivity activity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InfoLine(label: 'Aracın adı', value: activity.vehicleCode, labelWidth: 180),
        InfoLine(label: 'Takviye yapılan bölge', value: activity.area, labelWidth: 180),
        InfoLine(label: 'Yağ takviyesi türü', value: activity.oilType, labelWidth: 180),
        InfoLine(
          label: 'Takviye miktarı',
          value: '${activity.amount.toStringAsFixed(1)} L',
          labelWidth: 180,
        ),
        InfoLine(
          label: 'Takviye tarihi',
          value: formatDateTime(activity.date),
          labelWidth: 180,
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- servis raporu

class _ReportDetails extends StatelessWidget {
  const _ReportDetails({required this.activity});

  final ServiceReportActivity activity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InfoLine(label: 'Rapor türü', value: activity.reportType, labelWidth: 180),
        if (activity.itemCount > 0)
          InfoLine(
            label: 'Rapordaki kayıt',
            value: '${activity.itemCount} satır',
            labelWidth: 180,
          ),
        InfoLine(
          label: 'Araç',
          value: activity.vehicleCode.isEmpty ? '-' : activity.vehicleCode,
          labelWidth: 180,
        ),
        InfoLine(
          label: 'Gönderim tarihi',
          value: formatDateTime(activity.date),
          labelWidth: 180,
        ),
        const SizedBox(height: 20),
        _SubTitle(text: 'Açıklama'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Text(
            activity.description.isEmpty ? 'Açıklama girilmedi.' : activity.description,
            style: TextStyle(
              height: 1.5,
              color: activity.description.isEmpty ? context.mutedColor : null,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _SubTitle(text: 'Gönderilen görseller (${activity.imagePaths.length})'),
        const SizedBox(height: 10),
        if (activity.imagePaths.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: <Widget>[
                Icon(Icons.image_not_supported_outlined,
                    size: 30, color: context.mutedColor),
                const SizedBox(height: 8),
                Text('Bu forma görsel eklenmemiş.',
                    style: TextStyle(color: context.mutedColor, fontSize: 13)),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: activity.imagePaths.length,
            itemBuilder: (BuildContext context, int i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _Thumb(path: activity.imagePaths[i]),
            ),
          ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
          color: context.cardColor,
          alignment: Alignment.center,
          child: Icon(Icons.broken_image_outlined, color: context.mutedColor),
        );

    if (kIsWeb) return Image.network(path, fit: BoxFit.cover);
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (BuildContext c, Object e, StackTrace? s) => fallback(),
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
