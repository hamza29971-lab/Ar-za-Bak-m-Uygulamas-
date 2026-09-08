import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/activity_details_dialog.dart';
import '../widgets/common.dart';
import '../widgets/nimo_page.dart';

/// Anasayfa: vardiya bilgileri, son işlemler kutucuğu ve tanıtım bloğu.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
    final List<ActivityRecord> activities = state.recentActivities();

    return NimoPage(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Üst bilgi şeridi
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.isDark
                    ? context.cardColor.withValues(alpha: 0.5)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    value: user == null || user.registryNo.trim().isEmpty
                        ? '-'
                        : user.registryNo,
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
                const SizedBox(width: 16),
                // Diğerleriyle aynı görünümde, ama basılabilir: son işlemler
                // listesi artık anasayfada durmuyor, buradan açılıyor.
                Expanded(
                  child: _InfoTile(
                    icon: Icons.history,
                    label: 'SON İŞLEMLER',
                    value: activities.isEmpty
                        ? 'Kayıt yok'
                        : '${activities.length} işlem',
                    hint: 'Görmek için dokunun',
                    onTap: () => _showActivities(context, state),
                  ),
                ),
              ],
            ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildIntro(context)),
          ],
        ),
      ),
    );
  }

  /// Anasayfanın tanıtım bloğu: solda açıklama, sağda araç görseli.
  Widget _buildIntro(BuildContext context) {
    // Üst şerit, alt sekme çubuğu ve boşluklar çıkarıldığında kalan yükseklik;
    // görsel buna göre ölçeklenir ki her pencerede kaydırmadan sığsın.
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double artHeight = ((screenHeight - 440) * 1.25).clamp(330.0, 680.0);
    final double titleSize = screenHeight >= 950
        ? 40
        : screenHeight >= 820
            ? 36
            : 30;

    final Widget heading = Text(
      'Lastik Değişim, Yağ Takviye ve Mekanik Operasyonlarınızı '
      'Bu Panelden Yönetebilirsiniz',
      style: TextStyle(
        fontSize: titleSize,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );

    // Görsel şeffaf zeminli olduğu için çerçevesiz, olduğu gibi yerleştirilir.
    final Widget art = Image.asset(
      'assets/images/anasayfa/EuclidAnasayfa.png',
      fit: BoxFit.contain,
      errorBuilder: (BuildContext context, Object e, StackTrace? s) =>
          const SizedBox.shrink(),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Dar ekranda görsel metnin altına iner.
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              heading,
              const SizedBox(height: 20),
              Expanded(child: Center(child: art)),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(flex: 44, child: heading),
            const SizedBox(width: 32),
            Expanded(flex: 56, child: art),
          ],
        );
      },
    );
  }

  /// "Son İşlemler" kutucuğu: listeyi pencerede açar.
  Future<void> _showActivities(BuildContext context, AppState state) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => _ActivitiesDialog(state: state),
    );
  }

}

/// "Son İşlemler" penceresi: kullanıcının son lastik değişimi, yağ takviyesi
/// ve form gönderimleri. Satıra dokunulduğunda türüne özel detay açılır.
class _ActivitiesDialog extends StatelessWidget {
  const _ActivitiesDialog({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final List<ActivityRecord> items = state.recentActivities();

    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(Icons.history, size: 22, color: context.brandColor),
          const SizedBox(width: 10),
          const Expanded(child: Text('Son İşlemler')),
          Text(
            items.isEmpty ? 'kayıt yok' : 'son ${items.length} işlem',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: context.mutedColor,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 640,
        child: items.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Henüz lastik değişimi, yağ takviyesi veya form gönderimi '
                  'yapılmadı.',
                  style: TextStyle(color: context.mutedColor),
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: context.borderColor),
                itemBuilder: (BuildContext context, int i) =>
                    _ActivityRow(activity: items[i]),
              ),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;

  /// Verilirse kutucuk butona dönüşür; görünüm diğerleriyle aynı kalır,
  /// yalnızca sağa küçük bir ok eklenir.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: context.isDark ? context.cardColor : context.pageColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: context.moduleBorderColor(Theme.of(context).colorScheme.primary),
          width: 2.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: context.mutedColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: context.mutedColor,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, size: 18, color: context.mutedColor),
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

    if (onTap == null) return tile;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: tile,
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final ActivityRecord activity;

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color color}) visual = activityVisual(activity.type);
    final Color tone = context.accent(visual.color);

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
                color: tone.withValues(alpha: context.isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(visual.icon, size: 18, color: tone),
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
