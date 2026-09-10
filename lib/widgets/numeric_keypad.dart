import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Uygulama içi sayı klavyesi.
///
/// Tabletin sistem klavyesi yerine kullanılır: sistem klavyesi ekranın
/// yarısını kaplayıp yerleşimi bozuyor, kiosk modunda ise üzerindeki
/// kısayollar kaçış yüzeyi oluşturuyor. Bağlı olduğu alan `readOnly`
/// bırakılır; düzenlemeyi bu panel yapar.
///
/// Hem giriş ekranındaki telefon alanı hem de kiosk çıkış parolası bu
/// bileşeni kullanır; görünüm iki yerde de aynıdır.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onClear,
    this.onDone,
    this.doneLabel = 'Tamam',
    this.enabled = true,
    this.stretch = false,
    this.keyWidth = 92,
    this.keyHeight = 56,
    this.accent,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// Verilirse sol alta "temizle" tuşu konur.
  final VoidCallback? onClear;

  /// Verilirse panelin altına tam genişlikte bir onay tuşu eklenir.
  final VoidCallback? onDone;

  final String doneLabel;
  final bool enabled;

  /// `true` ise tuşlar satırı doldurur (genişliği belli bir sütuna
  /// oturtmak için); `false` ise [keyWidth] kadar yer kaplar.
  final bool stretch;

  final double keyWidth;
  final double keyHeight;

  /// Onay tuşunun rengi; verilmezse marka yeşili kullanılır.
  final Color? accent;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final List<String> row in const <List<String>>[
          <String>['1', '2', '3'],
          <String>['4', '5', '6'],
          <String>['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: _gap),
            child: _row(<Widget>[
              for (final String digit in row)
                _key(
                  context,
                  onTap: () => onDigit(digit),
                  child: Text(
                    digit,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w600),
                  ),
                ),
            ]),
          ),
        _row(<Widget>[
          if (onClear != null)
            _key(
              context,
              onTap: onClear!,
              tone: context.accent(AppColors.emergency),
              child: const Icon(Icons.clear, size: 24),
            )
          else
            _spacer(),
          _key(
            context,
            onTap: () => onDigit('0'),
            child: const Text(
              '0',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
            ),
          ),
          _key(
            context,
            onTap: onBackspace,
            child: const Icon(Icons.backspace_outlined, size: 22),
          ),
        ]),
        if (onDone != null) ...<Widget>[
          const SizedBox(height: _gap),
          SizedBox(
            width: stretch ? double.infinity : (keyWidth * 3 + _gap * 2),
            child: FilledButton.icon(
              onPressed: enabled ? onDone : null,
              style: FilledButton.styleFrom(
                backgroundColor:
                    context.accentFill(accent ?? AppColors.brand),
                padding: EdgeInsets.symmetric(vertical: keyHeight / 3.6),
              ),
              icon: const Icon(Icons.keyboard_hide_outlined, size: 20),
              label: Text(doneLabel,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(List<Widget> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < keys.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: _gap),
          if (stretch) Expanded(child: keys[i]) else keys[i],
        ],
      ],
    );
  }

  /// Temizle tuşu yokken 0'ın ortada kalmasını sağlar.
  Widget _spacer() => SizedBox(width: stretch ? 0 : keyWidth, height: keyHeight);

  Widget _key(
    BuildContext context, {
    required VoidCallback onTap,
    required Widget child,
    Color? tone,
  }) {
    final Color foreground = tone ??
        (context.isDark ? AppColors.darkText : AppColors.lightText);
    final Color color = enabled ? foreground : context.mutedColor;

    return Material(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        // Tuşlar odağı ÇALMAMALI: odak metin alanında kalmazsa imleç
        // kaybolur ve panel kendini kapatır.
        canRequestFocus: false,
        child: Container(
          width: stretch ? null : keyWidth,
          height: keyHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: color),
            child: IconTheme.merge(
              data: IconThemeData(color: color),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
