import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'service_report_screen.dart';
import 'home_screen.dart';
import 'oil_screen.dart';
import '../ui/screens/tire_change_screen.dart';

/// Giriş sonrası ana iskelet: alt sekme çubuğu + sayfalar.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late int _index = widget.initialIndex;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem('Anasayfa', Icons.home_outlined, Icons.home_rounded, AppColors.brand),
    _NavItem('Lastik Değişimi', Icons.trip_origin, Icons.trip_origin, AppColors.tire),
    _NavItem('Yağ Takviyesi', Icons.water_drop_outlined, Icons.water_drop, AppColors.oil),
    _NavItem('Servis Raporu', Icons.description_outlined, Icons.description,
        AppColors.form),
    _NavItem('Mekanik Operasyon', Icons.build_outlined, Icons.build,
        AppColors.mechanic),
  ];

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: <Widget>[
            const HomeScreen(),
            const TireChangeScreen(),
            const OilScreen(),
            // Servis raporunda görsel yalnızca kamerayla eklenir ve servisin
            // başlangıç / bitiş saati seçilir.
            const ServiceReportScreen(allowGallery: false),
            const ServiceReportScreen(
              title: 'Mekanik Operasyon',
              type: ReportType.mechanical,
              accent: AppColors.mechanic,
              allowGallery: false,
              showServiceHours: false,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.pageColor,
          border: Border(top: BorderSide(color: context.borderColor)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 86,
            child: Row(
              children: <Widget>[
                for (int i = 0; i < _items.length; i++) ...[
                  if (i > 0)
                    // Sekmeler arasındaki ayraç; normal kenarlıktan daha
                    // koyu ve uzun olsun ki sınır net görünsün.
                    Container(
                      width: 2,
                      height: 56,
                      color: context.strongBorderColor,
                    ),
                  Expanded(
                    child: _NavButton(
                      item: _items[i],
                      selected: i == _index,
                      onTap: () => _go(i),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon, this.color);

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color color;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color =
        selected ? context.accent(item.color) : context.mutedColor;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(selected ? item.activeIcon : item.icon, size: 28, color: color),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 15,
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
