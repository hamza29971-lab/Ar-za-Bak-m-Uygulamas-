import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Üst bardaki dişli butonundan açılan Ayarlar ekranı.
///
/// Uygulamada profil bölümü bulunmaz; bu ekran yalnızca tema tercihi ve
/// güncelleme kontrolü gibi sistem ayarlarını barındırır.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 24, 12),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Geri',
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Ayarlar',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.borderColor),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'GÖRÜNÜM',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            color: context.mutedColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ThemeOption(
                          icon: Icons.phone_android,
                          title: 'Sistem',
                          subtitle:
                              'Cihazın açık veya koyu mod ayarını kullanır',
                          selected: state.themeMode == ThemeMode.system,
                          onTap: () => state.themeMode = ThemeMode.system,
                        ),
                        const SizedBox(height: 12),
                        _ThemeOption(
                          icon: Icons.light_mode_outlined,
                          title: 'Açık tema',
                          selected: state.themeMode == ThemeMode.light,
                          onTap: () => state.themeMode = ThemeMode.light,
                        ),
                        const SizedBox(height: 12),
                        _ThemeOption(
                          icon: Icons.dark_mode_outlined,
                          title: 'Koyu tema',
                          selected: state.themeMode == ThemeMode.dark,
                          onTap: () => state.themeMode = ThemeMode.dark,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'UYGULAMA',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            color: context.mutedColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Uygulama güncel (v${AppState.appVersion}).'),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 18),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.borderColor),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.cloud_download_outlined,
                                    size: 22),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Text('Güncellemeleri Kontrol Et',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Yeni sürüm olup olmadığını kontrol '
                                        'eder (kurulu: v${AppState.appVersion})',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: context.mutedColor),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: context.mutedColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: selected ? context.brandSoftColor : context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? context.accent(AppColors.brandLight)
                : context.borderColor,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 22, color: selected ? context.brandColor : null),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selected ? context.brandColor : null,
                      )),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(subtitle!,
                        style:
                            TextStyle(fontSize: 13, color: context.mutedColor)),
                  ],
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? context.brandColor : context.mutedColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
