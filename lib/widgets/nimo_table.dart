import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NimoColumn {
  const NimoColumn(
    this.label, {
    this.flex = 1,
    this.align = Alignment.centerLeft,
    this.headerInset = 0,
  });

  final String label;
  final int flex;
  final Alignment align;

  /// Yalnızca başlık metnini sağa kaydırır; hücre içeriği etkilenmez.
  /// Butonlara geniş yer ayrılan "İşlem" sütununda başlığı hizalamak için.
  final double headerInset;
}

/// Lastik / yağ listelerinde kullanılan sade tablo kartı.
class NimoTable extends StatelessWidget {
  const NimoTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.cellsBuilder,
    this.accent,
    this.empty,
    this.shrinkWrap = false,
  });

  final List<NimoColumn> columns;
  final int rowCount;

  /// Her satır için hücre listesi; uzunluğu [columns] ile aynı olmalıdır.
  final List<Widget> Function(BuildContext context, int index) cellsBuilder;
  final Color? accent;
  final Widget? empty;

  /// `true` ise tablo yüksekliğini satırlarına göre alır ve kendi içinde
  /// kaydırmaz; tüm satırlar alt alta görünür (sayfa kaydırılarak okunur).
  /// `false` (varsayılan) ise verilen yüksekliği doldurur ve liste kaydırılır.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final Color color = accent ?? Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: context.pageColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: context.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        children: <Widget>[
          // Başlık satırı
          Container(
            color: context.cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                for (final NimoColumn c in columns)
                  Expanded(
                    flex: c.flex,
                    child: Padding(
                      padding: EdgeInsets.only(left: c.headerInset),
                      child: Align(
                        alignment: c.align,
                        child: Text(
                          c.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: context.borderColor),
          if (shrinkWrap) _buildRows(context) else Expanded(child: _buildRows(context)),
        ],
      ),
    );
  }
}


extension on NimoTable {
  Widget _buildRows(BuildContext context) {
    if (rowCount == 0) return empty ?? const SizedBox.shrink();

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: rowCount,
      separatorBuilder: (_, _) => Divider(height: 1, color: context.borderColor),
      itemBuilder: (BuildContext context, int index) {
        final List<Widget> cells = cellsBuilder(context, index);
        assert(cells.length == columns.length,
            'Hücre sayısı sütun sayısıyla eşleşmeli');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < columns.length; i++)
                Expanded(
                  flex: columns[i].flex,
                  child: Align(alignment: columns[i].align, child: cells[i]),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Tablo hücrelerinde kullanılan iki satırlı metin.
class CellText extends StatelessWidget {
  const CellText(this.title, {super.key, this.subtitle, this.bold = false, this.color});

  final String title;
  final String? subtitle;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(subtitle!, style: TextStyle(fontSize: 12, color: context.mutedColor)),
        ],
      ],
    );
  }
}

/// Tablo satırlarındaki aksiyon butonu.
class RowActionButton extends StatelessWidget {
  const RowActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.filled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = filled
        ? FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: color,
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            side: BorderSide(color: color.withValues(alpha: 0.5)),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          );

    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );

    return filled
        ? FilledButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}
