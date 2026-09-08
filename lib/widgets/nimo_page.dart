import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../providers/tire_change_provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../ui/screens/login_screen.dart';
import 'battery_indicator.dart';
import 'nimo_logo.dart';
import 'notifications_dialog.dart';

/// Tüm sayfalarda kullanılan üst bar.
///
/// Solda robot logosu ve uygulamanın adı; sağ kenarda tema anahtarı, "Geçmiş"
/// zili, tabletin pil göstergesi ve "Çıkış" yer alır.
/// Uygulamada profil bölümü yoktur.
/// Sayfa adı üst barda değil, sayfanın kendi içeriğinin üstünde [PageHeading]
/// ile gösterilir.
class NimoTopBar extends StatelessWidget {
  const NimoTopBar({super.key, this.leading});

  /// Uygulamanın tüm sayfalarda görünen adı.
  static const String brandName = 'Nuh Intelligent Mining Operations';

  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return _bar(context, AppScope.of(context));
  }

  Widget _bar(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: context.pageColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[leading!, const SizedBox(width: 8)],
          const NimoLogo(),
          const SizedBox(width: 14),
          // Başlık bloğu kalan genişliğin tamamını alır; böylece sağdaki eylem
          // grubu her zaman sayfanın sağ kenarına yaslanır.
          // Marka bloğu kalan genişliğin tamamını alır; böylece sağdaki eylem
          // grubu her zaman sayfanın sağ kenarına yaslanır.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'NIMO',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                    color: context.mutedColor,
                  ),
                ),
                Text(
                  brandName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _CircleAction(
            icon: context.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            tooltip: context.isDark ? 'Açık tema' : 'Koyu tema',
            onTap: () => state.themeMode =
                context.isDark ? ThemeMode.light : ThemeMode.dark,
          ),
          const SizedBox(width: 10),
          _CircleAction(
            icon: Icons.history,
            tooltip: 'Geçmiş',
            badge: state.unreadCount,
            onTap: () => showNotificationsDialog(context),
          ),
          const SizedBox(width: 10),
          // Tabletin şarj durumu; "Geçmiş" ile "Çıkış" arasında.
          const BatteryIndicator(),
          const SizedBox(width: 10),
          _LogoutButton(),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog<void>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.35),
          builder: (BuildContext dialogContext) => _LogoutDialog(
            onConfirm: () {
              Navigator.of(dialogContext).pop();
              AppScope.read(context).signOut();
              context.read<TireChangeProvider>().clearSelectedVehicle();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
          ),
        );
      },
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Çıkış', style: TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.accentSoft(AppColors.emergency,
            light: 0.10, dark: 0.16),
        foregroundColor: context.accent(AppColors.emergency),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

/// Çıkış onayı. Uygulamadaki diğer pencerelerle (bkz. [pending_send_dialog.dart],
/// [result_dialog.dart]) aynı düzen: renkli simge + başlık, altında mesaj ve
/// alt sırada eylemler.
class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final Color tone = context.accent(AppColors.emergency);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
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
                    child: Icon(Icons.logout, color: tone, size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Çıkış Yap',
                            style: TextStyle(
                                fontSize: 27, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Oturumunuz kapatılacak',
                            style: TextStyle(
                                fontSize: 17, color: context.mutedColor)),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 26, 32, 26),
              child: const SizedBox(
                width: double.infinity,
                child: Text(
                  'Çıkış yapmak istediğinize emin misiniz? '
                  'Gönderilmeyi bekleyen işlemler varsa önce onları gönderin.',
                  style: TextStyle(fontSize: 17, height: 1.5),
                ),
              ),
            ),
            Divider(height: 1, color: context.borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                    ),
                    child: Text('İptal',
                        style: TextStyle(
                            fontSize: 17, color: context.mutedColor)),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.accentFill(AppColors.emergency),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 34, vertical: 20),
                    ),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Çıkış Yap',
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

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badge = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: Icon(icon, size: 21),
            ),
            if (badge > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 18),
                  decoration: BoxDecoration(
                    color: context.accent(AppColors.emergency),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: context.pageColor, width: 2),
                  ),
                  child: Text(
                    badge > 9 ? '9+' : '$badge',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Üst bar + sayfa içeriğini birleştiren ortak iskelet.
class NimoPage extends StatelessWidget {
  const NimoPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const NimoTopBar(),
        // İçerik alanı açık temada hafif gri; tablolar, paneller ve kartlar
        // bunun üzerinde beyaz kalarak ayrışır.
        Expanded(
          child: ColoredBox(
            color: context.contentColor,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Sayfa içeriğinin üstünde yer alan sayfa başlığı.
/// Ör. "Araç Seç" alanının hemen üstündeki "Lastik Değişimi" yazısı.
class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.title, this.subtitle, this.titleSize = 26});

  final String title;
  final String? subtitle;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w700),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 13, color: context.mutedColor),
          ),
        ],
      ],
    );
  }
}
