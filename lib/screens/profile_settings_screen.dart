import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../ui/screens/login_screen.dart';

/// Sağ üstteki "Profil" butonundan açılan Profil Bilgileri / Ayarlar ekranı.
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key, this.initialTab = 0});

  /// 0: Profil Bilgileri, 1: Ayarlar
  final int initialTab;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late int _tab = widget.initialTab;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 900;
            if (!wide) {
              return Column(
                children: <Widget>[
                  SizedBox(height: 320, child: _buildMenu(context)),
                  Divider(height: 1, color: context.borderColor),
                  Expanded(child: _buildDetail(context)),
                ],
              );
            }
            return Row(
              children: <Widget>[
                SizedBox(width: 380, child: _buildMenu(context)),
                VerticalDivider(width: 1, color: context.borderColor),
                Expanded(child: _buildDetail(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ sol menü
  Widget _buildMenu(BuildContext context) {
    final List<_MenuEntry> entries = <_MenuEntry>[
      const _MenuEntry(
        index: 0,
        icon: Icons.account_circle_outlined,
        title: 'Profil Bilgileri',
        subtitle: 'Profil bilgilerinizi görüntüleyin ve düzenleyin.',
      ),
      const _MenuEntry(
        index: 1,
        icon: Icons.settings_outlined,
        title: 'Ayarlar',
        subtitle: 'Sistem ayarlarınızı yönetin.',
      ),
    ];
    final List<_MenuEntry> filtered = _query.trim().isEmpty
        ? entries
        : entries
            .where((_MenuEntry e) =>
                e.title.toLowerCase().contains(_query.toLowerCase()) ||
                e.subtitle.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Column(
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
              const Expanded(
                child: Text(
                  'Ayarlar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
        Divider(height: 1, color: context.borderColor),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Ara',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (String v) => setState(() => _query = v),
                ),
                const SizedBox(height: 18),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final _MenuEntry e in filtered) ...<Widget>[
                        Expanded(
                          child: _MenuCard(
                            entry: e,
                            selected: _tab == e.index,
                            onTap: () => setState(() => _tab = e.index),
                          ),
                        ),
                        if (e != filtered.last) const SizedBox(width: 14),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _feedbackDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.chat_bubble_outline, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Öneri / şikayet gönder',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        Icon(Icons.chevron_right, color: context.mutedColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            children: <Widget>[
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: <Widget>[
                  Text('Yardıma mı ihtiyacınız var?',
                      style: TextStyle(fontSize: 13, color: context.mutedColor)),
                  TextButton.icon(
                    onPressed: () => _supportDialog(context),
                    icon: const Icon(Icons.phone_outlined, size: 16),
                    label: const Text('Destek ile İletişim'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.brand),
                  ),
                ],
              ),
              Text('Nimo sürüm ${AppState.appVersion}',
                  style: TextStyle(fontSize: 12, color: context.mutedColor)),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- sağ panel
  Widget _buildDetail(BuildContext context) {
    return _tab == 0 ? _buildProfile(context) : _buildSettings(context);
  }

  Widget _buildProfile(BuildContext context) {
    final AppState state = AppScope.of(context);
    final UserProfile? user = state.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text('Profil bilgileri',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Hesabınız',
                    style: TextStyle(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.brandSoft,
                  child: Text(
                    user?.initials ?? '?',
                    style: const TextStyle(
                        color: AppColors.brand,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(user?.fullName ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.mutedColor, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('DETAYLAR',
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: context.mutedColor)),
          const SizedBox(height: 12),
          _DetailRow(
              icon: Icons.person_outline, label: 'AD SOYAD', value: user?.fullName ?? '-'),
          _DetailRow(
              icon: Icons.mail_outline, label: 'E-POSTA', value: user?.email ?? '-'),
          _DetailRow(
              icon: Icons.phone_outlined, label: 'TELEFON', value: user?.phone ?? '-'),
          _DetailRow(icon: Icons.badge_outlined, label: 'ROL', value: user?.role ?? '-'),
          _DetailRow(
              icon: Icons.vpn_key_outlined,
              label: 'SİCİL / KİMLİK',
              value: user?.registryNo ?? '-'),
          _DetailRow(
              icon: Icons.precision_manufacturing_outlined,
              label: 'MAKİNE',
              value: state.selectedVehicle?.code ?? user?.machineCode ?? '-'),
          _DetailRow(
              icon: Icons.sell_outlined,
              label: 'MAKİNE TÜRÜ',
              value: state.selectedVehicle?.type ?? user?.machineType ?? '-'),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, state),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.emergency,
                side: BorderSide(color: AppColors.emergency.withValues(alpha: 0.4)),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Çıkış Yap'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    final AppState state = AppScope.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Ayarlar',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 22),
          _ThemeOption(
            icon: Icons.phone_android,
            title: 'Sistem',
            subtitle: 'Cihazın açık veya koyu mod ayarını kullanır',
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
          const SizedBox(height: 24),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Uygulama güncel (v${AppState.appVersion}).')),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.cloud_download_outlined, size: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Güncellemeleri Kontrol Et',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(
                          'Yeni sürüm olup olmadığını kontrol eder (kurulu: v${AppState.appVersion})',
                          style: TextStyle(fontSize: 13, color: context.mutedColor),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: context.mutedColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ dialoglar
  Future<void> _feedbackDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final bool? sent = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Öneri / Şikayet'),
        content: SizedBox(
          width: 460,
          child: TextField(
            controller: controller,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Görüşünüzü buraya yazın...',
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesajınız iletildi. Teşekkür ederiz.')),
      );
    }
    controller.dispose();
  }

  Future<void> _supportDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: const Icon(Icons.support_agent, color: AppColors.brand, size: 40),
        title: const Text('Destek ile İletişim'),
        content: const SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              InfoLine(label: 'Bakım Şefliği', value: '0262 316 20 00', labelWidth: 140),
              InfoLine(label: 'Bilgi İşlem', value: '0262 316 21 21', labelWidth: 140),
              InfoLine(
                  label: 'E-posta', value: 'destek@nuhcimento.com.tr', labelWidth: 140),
            ],
          ),
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AppState state) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Oturumunuzu kapatmak istediğinize emin misiniz?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await state.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }
}

class _MenuEntry {
  const _MenuEntry({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final int index;
  final IconData icon;
  final String title;
  final String subtitle;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final _MenuEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandSoft.withValues(alpha: 0.35) : context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.brandLight : context.borderColor,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF5B6BE1).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(entry.icon, color: const Color(0xFF5B6BE1), size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              entry.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.brand : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(entry.subtitle,
                style: TextStyle(fontSize: 12.5, color: context.mutedColor, height: 1.35)),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF5B6BE1).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: const Color(0xFF5B6BE1)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                          color: context.mutedColor)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
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
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.brandLight : context.borderColor,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 22, color: selected ? AppColors.brand : null),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.brand : null,
                      )),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(subtitle!,
                        style: TextStyle(fontSize: 13, color: context.mutedColor)),
                  ],
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.brand : context.mutedColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
