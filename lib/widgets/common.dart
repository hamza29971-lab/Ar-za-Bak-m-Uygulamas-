import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Liste boşken gösterilen bilgi bloğu.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    // Alan yeterliyse ortalanır; kısa alanlarda (ör. bölünmüş ekranlarda)
    // taşma yerine kaydırılır.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
            ),
            child: _buildContent(context),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 44, color: context.mutedColor),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              width: 380,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.mutedColor, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [SegmentedTabs] içindeki bir sekme.
class SegmentedTabItem<T> {
  const SegmentedTabItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  final T value;
  final String label;
  final IconData icon;
}

/// Liste üstünde kullanılan grup seçim sekmeleri
/// (ör. "Yağ Takviyeleri / Manuel Yağlamalar", "Sol / Sağ").
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    required this.accent,
  });

  final List<SegmentedTabItem<T>> items;
  final T selected;
  final ValueChanged<T> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final SegmentedTabItem<T> item in items)
            _SegmentedTab(
              label: item.label,
              icon: item.icon,
              selected: item.value == selected,
              accent: accent,
              onTap: () => onChanged(item.value),
            ),
        ],
      ),
    );
  }
}

class _SegmentedTab extends StatelessWidget {
  const _SegmentedTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tone = context.accent(accent);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? tone.withValues(alpha: context.isDark ? 0.18 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? tone.withValues(alpha: 0.35) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 17, color: selected ? tone : context.mutedColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? tone : context.mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Küçük renkli bilgi rozeti.
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Color tone = context.accent(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: context.isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: tone),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tone),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiket + değer satırı (onay pencereleri, profil detayları).
class InfoLine extends StatelessWidget {
  const InfoLine({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 150,
  });

  final String label;
  final String value;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: labelWidth,
            child: Text(label, style: TextStyle(color: context.mutedColor, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Başlıklı beyaz/gri kart.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.accent,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
    this.expandChild = false,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Color? accent;
  final Widget? trailing;
  final EdgeInsets padding;

  /// Kart sınırlı yükseklikteyse (ör. [Expanded] içindeyse) içeriği doldurur.
  /// Kaydırılabilir alanlarda `false` bırakılmalıdır.
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final Color color =
        context.accent(accent ?? Theme.of(context).colorScheme.primary);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.isDark ? context.cardColor : context.pageColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: context.isDark ? 0.16 : 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(title!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

/// Tablonun üstünde, sekmelerin sağında duran ana işlem butonu
/// ("Takviye Yap", "Lastik Değiştir"). Tablodaki satır butonlarından ayrışsın
/// diye biraz daha büyük, yuvarlak hatlı ve ikonu çerçeve içinde.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.accent,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.filled = true,
    this.badge,
    this.compact = false,
  });

  final String label;
  final Color accent;

  /// `null` verilirse buton soluk ve tıklanamaz olur.
  final VoidCallback? onPressed;

  final IconData icon;

  /// `false` ise dolgusuz, yalnızca çerçeveli çizilir (ikincil işlemler).
  final bool filled;

  /// Etiketin sonuna eklenen küçük sayaç (ör. bekleyen işlem sayısı).
  final int? badge;

  /// İkincil işlemler için daha dar hâli: ikon çerçevesiz, iç boşluk küçük.
  /// Aynı satırda birden fazla buton olduğunda yer kazandırır; böylece üç
  /// buton dar tablette de sekmelerin yanında kalabilir.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color base = enabled
        ? (filled ? context.accentFill(accent) : context.accent(accent))
        : context.mutedColor.withValues(alpha: 0.35);
    final Color fg = filled ? Colors.white : base;
    final BorderRadius radius = BorderRadius.circular(12);

    return Material(
      color: filled ? base : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 14,
            vertical: compact ? 9 : 9,
          ),
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: base.withValues(alpha: 0.55), width: 1.5),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (compact)
                Icon(icon, size: 16, color: fg)
              else
                Container(
                  width: 21,
                  height: 21,
                  decoration: BoxDecoration(
                    color: filled
                        ? Colors.white.withValues(alpha: 0.22)
                        : base.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: fg),
                ),
              SizedBox(width: compact ? 6 : 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              if (badge != null) ...<Widget>[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: filled
                        ? Colors.white.withValues(alpha: 0.24)
                        : base.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
