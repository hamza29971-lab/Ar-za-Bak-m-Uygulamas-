import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/activity_details_dialog.dart';
import '../widgets/common.dart';
import '../widgets/nimo_page.dart';
import '../widgets/vehicle_photo.dart';

/// Anasayfa: vardiya özeti, hızlı işlemler ve son hareketler.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate});

  /// Alt sekmelere geçiş (1: Lastik, 2: Yağ, 3: Form).
  final ValueChanged<int> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final UserProfile? user = state.user;
    final Vehicle? vehicle = state.selectedVehicle;

    return NimoPage(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Üst bilgi şeridi
            Row(
              children: <Widget>[
                Expanded(
                  child: _InfoTile(
                    icon: Icons.person_outline,
                    label: 'KULLANICI',
                    value: user?.fullName ?? '-',
                    hint: user?.role ?? '',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'SİCİL NO',
                    value: user?.registryNo ?? '-',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.schedule,
                    label: 'ZAMAN',
                    value: formatTime(_now),
                    hint: formatFullDate(_now),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildActivities(context, state),
            const SizedBox(height: 20),

            // Özet + hızlı işlemler
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(flex: 62, child: _buildActions(context, state, vehicle)),
                  const SizedBox(width: 20),
                  Expanded(flex: 38, child: _buildVehicleCard(context, vehicle)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, AppState state, Vehicle? vehicle) {
    final List<TireRecord> tires =
        vehicle == null ? <TireRecord>[] : state.tiresOf(vehicle);
    final List<OilRecord> oils = vehicle == null ? <OilRecord>[] : state.oilsOf(vehicle);
    final int tireOverdue =
        tires.where((TireRecord r) => daysSince(r.lastCheckDate) > 30).length;

    return SectionCard(
      title: 'Hızlı İşlemler',
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _ActionCard(
                  color: AppColors.tire,
                  icon: Icons.trip_origin,
                  title: 'Lastik Değişimi',
                  subtitle: vehicle == null
                      ? 'Araç seçilmedi'
                      : '${tires.length} lastik kaydı',
                  badge: tireOverdue > 0 ? '$tireOverdue kontrol gecikti' : null,
                  onTap: () => widget.onNavigate(1),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ActionCard(
                  color: AppColors.oil,
                  icon: Icons.water_drop_outlined,
                  title: 'Yağ Takviyesi',
                  subtitle:
                      vehicle == null ? 'Araç seçilmedi' : '${oils.length} alan kaydı',
                  onTap: () => widget.onNavigate(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ActionCard(
                  color: AppColors.form,
                  icon: Icons.description_outlined,
                  title: 'Servis Raporu',
                  subtitle: 'Rapor oluştur ve gönder',
                  onTap: () => widget.onNavigate(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatBox(
                  label: 'Bekleyen lastik kontrolü',
                  value: '$tireOverdue',
                  icon: Icons.trip_origin,
                  color: tireOverdue > 0 ? AppColors.fault : AppColors.brand,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StatBox(
                  // Yağ takviyesi için süre kuralı yok; toplam kayıt gösterilir.
                  label: 'Yağ takviyesi kaydı',
                  value: '${oils.length}',
                  icon: Icons.water_drop_outlined,
                  color: AppColors.oil,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StatBox(
                  label: 'Okunmamış bildirim',
                  value: '${state.unreadCount}',
                  icon: Icons.notifications_none,
                  color: AppColors.form,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Vehicle? vehicle) {
    // Başlık satırı kaldırıldı; kart yalnızca aracın görselini gösterir.
    return SectionCard(
      child: SizedBox(
        height: 260,
        child: VehiclePhoto(vehicle: vehicle),
      ),
    );
  }

  /// Kullanıcının son 10 lastik değişimi, yağ takviyesi ve form gönderimi.
  /// Satıra dokunulduğunda türüne özel detay penceresi açılır.
  Widget _buildActivities(BuildContext context, AppState state) {
    final List<ActivityRecord> items = state.recentActivities();

    return SectionCard(
      title: 'Son İşlemler',
      icon: Icons.history,
      trailing: Text(
        items.isEmpty ? 'kayıt yok' : 'son ${items.length} işlem',
        style: TextStyle(fontSize: 13, color: context.mutedColor),
      ),
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Henüz lastik değişimi, yağ takviyesi veya form gönderimi yapılmadı.',
                  style: TextStyle(color: context.mutedColor),
                ),
              ),
            )
          : SizedBox(
              height: items.length > 5 ? 330 : null,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: items.length <= 5,
                physics: items.length > 5
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: context.borderColor),
                itemBuilder: (BuildContext context, int i) =>
                    _ActivityRow(activity: items[i]),
              ),
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: context.pageColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: context.mutedColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: context.mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          if (hint != null && hint!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: context.mutedColor)),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: context.mutedColor)),
            if (badge != null) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.fault.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.fault,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(value,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, color: color)),
                Text(label,
                    maxLines: 2,
                    style: TextStyle(fontSize: 11, color: context.mutedColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Son İşlemler" listesindeki tek satır.
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final ActivityRecord activity;

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color color}) visual = activityVisual(activity.type);

    return InkWell(
      onTap: () => showActivityDetails(context, activity),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: visual.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(visual.icon, size: 18, color: visual.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(activity.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(activity.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.mutedColor)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(relativeTime(activity.date),
                style: TextStyle(fontSize: 12, color: context.mutedColor)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: context.mutedColor),
          ],
        ),
      ),
    );
  }
}
