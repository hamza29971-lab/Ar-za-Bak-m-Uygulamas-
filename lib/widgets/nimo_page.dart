import 'package:flutter/material.dart';

import '../models/models.dart';
import '../screens/profile_settings_screen.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../ui/screens/login_screen.dart';
import 'nimo_logo.dart';
import 'notifications_dialog.dart';

/// Tüm sayfalarda kullanılan üst bar.
///
/// Solda robot logosu ve uygulamanın adı, sağ kenarda tema anahtarı,
/// "Bildirimler" zili ve "Profil" yer alır. Sayfa adı üst barda değil,
/// sayfanın kendi içeriğinin üstünde [PageHeading] ile gösterilir.
class NimoTopBar extends StatelessWidget {
  const NimoTopBar({super.key, this.leading});

  /// Uygulamanın tüm sayfalarda görünen adı.
  static const String brandName = 'Nuh Intelligent Mining Operations';

  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final UserProfile? user = state.user;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Dar tabletlerde profil adı gizlenir.
        final bool compactProfile = constraints.maxWidth < 1080;
        return _bar(context, state, user, compactProfile);
      },
    );
  }

  Widget _bar(
    BuildContext context,
    AppState state,
    UserProfile? user,
    bool compactProfile,
  ) {
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
          _ProfileButton(user: user, compact: compactProfile),
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
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Çıkış Yap'),
              content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Çıkış', style: TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFDE8E8),
        foregroundColor: Colors.red,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
                    color: AppColors.emergency,
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

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.user, this.compact = false});

  final UserProfile? user;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Profil',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ProfileSettingsScreen(),
          ),
        ),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: Center(
            child: CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.brandSoft,
              child: Text(
                user?.initials ?? '?',
                style: const TextStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
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
        Expanded(child: child),
      ],
    );
  }
}

/// Sayfa içeriğinin üstünde yer alan sayfa başlığı.
/// Ör. "Araç Seç" alanının hemen üstündeki "Lastik Değişimi" yazısı.
class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
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
