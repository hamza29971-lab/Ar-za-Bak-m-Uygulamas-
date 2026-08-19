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
            HomeScreen(onNavigate: _go),
            const TireChangeScreen(),
            const OilScreen(),
            const ServiceReportScreen(),
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
            height: 74,
            child: Row(
              children: <Widget>[
                for (int i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: _items[i],
                      selected: i == _index,
                      onTap: () => _go(i),
                    ),
                  ),
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
    final Color color = selected ? item.color : context.mutedColor;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(selected ? item.activeIcon : item.icon, size: 24, color: color),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
