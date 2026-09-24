import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Araç seçim listelerinin üstündeki tip filtresi.
///
/// Filo büyüdükçe uzun listeden araç bulmak zorlaştığı için, hem Yağ
/// Takviyesi / Servis Raporu / Mekanik Operasyon ekranlarındaki
/// [VehicleSelector] hem de Lastik Değişimi ekranının kendi araç seçicisi
/// bu satırı kullanır. Filtre ayrıntılı `type` koduna değil, geniş
/// kategoriye (`Kamyon` / `Ekskavatör` / `Loder`) göre çalışır — bkz.
/// `vehicleCategoryOf`.
class VehicleTypeFilter extends StatelessWidget {
  const VehicleTypeFilter({
    super.key,
    required this.categories,
    required this.selected,
    required this.onChanged,
    this.accent,
  });

  /// Filtrede gösterilecek kategoriler, sırayla (`Kamyon`, `Ekskavatör`, `Loder`).
  final List<String> categories;

  /// Seçili kategori; `null` ise "Tümü".
  final String? selected;

  final ValueChanged<String?> onChanged;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    if (categories.length < 2) return const SizedBox.shrink();

    final Color tone = accent ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: <Widget>[
          _chip(
            context,
            label: 'Tümü',
            isOn: selected == null,
            tone: tone,
            onTap: () => onChanged(null),
          ),
          for (final String category in categories)
            _chip(
              context,
              label: category,
              isOn: selected == category,
              tone: tone,
              onTap: () => onChanged(selected == category ? null : category),
            ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool isOn,
    required Color tone,
    required VoidCallback onTap,
  }) {
    final Color active = context.accent(tone);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isOn ? active.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isOn ? active : context.borderColor,
                width: isOn ? 1.8 : 1.2,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isOn ? FontWeight.w700 : FontWeight.w500,
                color: isOn ? active : context.mutedColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
