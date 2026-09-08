import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Üst barın sağ köşesinde tabletin şarj durumunu gösteren pil göstergesi.
///
/// Pil seviyesi 30 saniyede bir ve şarj durumu her değiştiğinde yenilenir.
/// Pili olmayan bir cihazda (ör. masaüstünde test) gösterge hiç çizilmez.
class BatteryIndicator extends StatefulWidget {
  const BatteryIndicator({super.key});

  @override
  State<BatteryIndicator> createState() => _BatteryIndicatorState();
}

class _BatteryIndicatorState extends State<BatteryIndicator> {
  /// Seviye için akış yok; bu aralıkla yoklanır.
  static const Duration _refreshInterval = Duration(seconds: 30);

  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _stateSub;
  Timer? _timer;

  int? _level;
  BatteryState _state = BatteryState.unknown;
  bool _unavailable = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(_refreshInterval, (_) => _refresh());
    _stateSub = _battery.onBatteryStateChanged.listen(
      (BatteryState state) {
        if (!mounted) return;
        setState(() => _state = state);
        // Fişe takıldığı anda seviye de tazelensin.
        _refresh();
      },
      onError: (Object _) {},
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final int level = await _battery.batteryLevel;
      final BatteryState state = await _battery.batteryState;
      if (!mounted) return;
      setState(() {
        _level = level.clamp(0, 100);
        _state = state;
        _unavailable = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Bir kez okunabildiyse son bilinen değeri koru.
      if (_level == null) setState(() => _unavailable = true);
    }
  }

  bool get _charging =>
      _state == BatteryState.charging || _state == BatteryState.full;

  Color _levelColor(BuildContext context, int level) {
    if (_charging) return context.accent(AppColors.brand);
    if (level <= 15) return context.accent(AppColors.emergency);
    if (level <= 30) return context.accent(AppColors.oil);
    return context.isDark ? AppColors.darkText : AppColors.lightText;
  }

  String get _stateLabel {
    switch (_state) {
      case BatteryState.charging:
        return 'şarj oluyor';
      case BatteryState.full:
        return 'tam dolu';
      case BatteryState.connectedNotCharging:
        return 'fişte, şarj olmuyor';
      case BatteryState.discharging:
      case BatteryState.unknown:
        return 'pilde';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int? level = _level;
    if (_unavailable || level == null) return const SizedBox.shrink();

    final Color color = _levelColor(context, level);
    return Tooltip(
      message: 'Tablet şarjı: %$level ($_stateLabel)',
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _BatteryGlyph(
              level: level,
              color: color,
              charging: _charging,
              trackColor: context.borderColor,
            ),
            const SizedBox(width: 8),
            Text(
              '%$level',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Doluluk oranı kadar dolan yatay pil simgesi.
class _BatteryGlyph extends StatelessWidget {
  const _BatteryGlyph({
    required this.level,
    required this.color,
    required this.charging,
    required this.trackColor,
  });

  final int level;
  final Color color;
  final bool charging;
  final Color trackColor;

  static const double _width = 30;
  static const double _height = 15;
  static const double _border = 1.6;

  @override
  Widget build(BuildContext context) {
    // Kalan yüzde çok düşükken bile ince bir çizgi görünsün.
    final double fill = level <= 0 ? 0 : (level / 100).clamp(0.06, 1.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: _width,
          height: _height,
          padding: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: trackColor, width: _border),
          ),
          child: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fill,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
              if (charging)
                Center(
                  child: Icon(
                    Icons.bolt,
                    size: 12,
                    color: context.pageColor,
                  ),
                ),
            ],
          ),
        ),
        // Pilin ucundaki kutup.
        Container(
          width: 2.5,
          height: 6,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}
