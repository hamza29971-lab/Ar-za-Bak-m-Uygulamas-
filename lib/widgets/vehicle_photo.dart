import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Aracın hangi tarafının gösterileceği.
/// "Lastik Değişimi" ekranındaki Sol / Sağ seçimi bu değeri belirler;
/// diğer ekranlar sol görünümü kullanır.
enum VehicleImageSide { left, right }

/// Taraflı görseli bulunan Euclid araçları (`Euclid-1` … `Euclid-11`) ve
/// Liugong araçları (`Liugong-16` … `Liugong-20`). Bunların dışındaki araçlar
/// genel görsele düşer.
const int _euclidSideImageCount = 11;
const int _liugongFirstSideImage = 16;
const int _liugongLastSideImage = 20;

/// `Euclid-4` + `euclid` -> 4, eşleşmezse `null`.
int? _vehicleNumber(String code, String prefix) {
  final RegExpMatch? match =
      RegExp('^$prefix-(\\d+)\$').firstMatch(code.trim().toLowerCase());
  return match == null ? null : int.tryParse(match.group(1)!);
}

/// Euclid araçlarının taraflı görselleri:
/// sol -> `assets/images/sol/Euclid[N].png` (Euclid-1 dosyası `Euclid.png`),
/// sağ -> `assets/images/sağ/Euclid[N]yansıma.png`.
String? _euclidSideAsset(String code, VehicleImageSide side) {
  final int? number = _vehicleNumber(code, 'euclid');
  if (number == null || number < 1 || number > _euclidSideImageCount) return null;

  if (side == VehicleImageSide.right) {
    return 'assets/images/sağ/Euclid${number}yansıma.png';
  }
  return number == 1
      ? 'assets/images/sol/Euclid.png'
      : 'assets/images/sol/Euclid$number.png';
}

/// Liugong araçlarının taraflı görselleri:
/// sol -> `assets/images/sol/Liugong[N].png`,
/// sağ -> `assets/images/sağ/Liugong[N]yansıma.png`.
String? _liugongSideAsset(String code, VehicleImageSide side) {
  final int? number = _vehicleNumber(code, 'liugong');
  if (number == null ||
      number < _liugongFirstSideImage ||
      number > _liugongLastSideImage) {
    return null;
  }

  return side == VehicleImageSide.right
      ? 'assets/images/sağ/Liugong${number}yansıma.png'
      : 'assets/images/sol/Liugong$number.png';
}

/// Euclid görsellerinin en-boy oranları (tuval ölçüleri sabit).
const double _leftViewAspectRatio = 1024 / 572;
const double _rightViewAspectRatio = 1024 / 660;

/// Görsel üzerindeki tıklanabilir tekerlek bölgesi.
/// [rect] görselin sol üst köşesine göre 0..1 aralığında normalize edilmiştir;
/// [position] araç tanımındaki konum adıyla birebir aynı olmalıdır.
@immutable
class TireHotspot {
  const TireHotspot(this.position, this.rect);

  final String position;
  final Rect rect;
}

/// Euclid sol görünümünde görünen tekerlekler (ön ve arka ikili).
const List<TireHotspot> _euclidLeftHotspots = <TireHotspot>[
  TireHotspot('Sol Ön', Rect.fromLTRB(0.335, 0.555, 0.550, 0.990)),
  TireHotspot('Sol Arka İç', Rect.fromLTRB(0.590, 0.550, 0.663, 0.930)),
  TireHotspot('Sol Arka Dış', Rect.fromLTRB(0.660, 0.550, 0.765, 0.930)),
];

/// Euclid sağ (yansımalı) görünümünde görünen tekerlekler.
const List<TireHotspot> _euclidRightHotspots = <TireHotspot>[
  TireHotspot('Sağ Ön', Rect.fromLTRB(0.365, 0.530, 0.590, 0.950)),
  TireHotspot('Sağ Arka İç', Rect.fromLTRB(0.265, 0.555, 0.355, 0.930)),
  TireHotspot('Sağ Arka Dış', Rect.fromLTRB(0.130, 0.555, 0.270, 0.930)),
];

/// Liugong sol görünümünde görünen tekerlekler (ön aks + ikili arka akslar).
/// İkili akslarda dıştaki tekerlek tam görünür, içteki onun arkasında kalır;
/// iç bölge görünen dar şeride yerleştirilmiştir.
const List<TireHotspot> _liugongLeftHotspots = <TireHotspot>[
  TireHotspot('Sol Ön', Rect.fromLTRB(0.480, 0.600, 0.640, 0.985)),
  TireHotspot('Sol Orta İç', Rect.fromLTRB(0.686, 0.640, 0.728, 0.935)),
  TireHotspot('Sol Orta Dış', Rect.fromLTRB(0.728, 0.640, 0.786, 0.935)),
  TireHotspot('Sol Arka İç', Rect.fromLTRB(0.786, 0.650, 0.820, 0.925)),
  TireHotspot('Sol Arka Dış', Rect.fromLTRB(0.820, 0.650, 0.858, 0.925)),
];

/// Liugong sağ (yansımalı) görünümünde görünen tekerlekler.
const List<TireHotspot> _liugongRightHotspots = <TireHotspot>[
  TireHotspot('Sağ Ön', Rect.fromLTRB(0.355, 0.615, 0.510, 0.985)),
  TireHotspot('Sağ Orta İç', Rect.fromLTRB(0.222, 0.660, 0.268, 0.925)),
  TireHotspot('Sağ Orta Dış', Rect.fromLTRB(0.165, 0.660, 0.222, 0.925)),
  TireHotspot('Sağ Arka İç', Rect.fromLTRB(0.128, 0.665, 0.165, 0.925)),
  TireHotspot('Sağ Arka Dış', Rect.fromLTRB(0.085, 0.665, 0.128, 0.925)),
];

/// Bir aracın görseli ve görsel üzerindeki tekerlek bölgeleri.
@immutable
class VehicleImageSpec {
  const VehicleImageSpec({
    required this.asset,
    this.aspectRatio,
    this.xShift = 0,
    this.hotspots = const <TireHotspot>[],
  });

  final String asset;

  /// Görselin en-boy oranı; tekerlek bölgelerinin doğru hizalanması için
  /// gereklidir. Bilinmiyorsa `null` (bölge de tanımlanmaz).
  final double? aspectRatio;

  /// Görselin kendi genişliğine oranla sağa ötelenme miktarı.
  final double xShift;

  final List<TireHotspot> hotspots;
}

/// Araç koduna göre görseller. Araç tipinden önce bakılır; böylece aynı tipteki
/// araçlar farklı markalar için ayrı görsel kullanabilir. Anahtar, araç kodunun
/// küçük harfli ön eki (`Euclid-4` -> `euclid`).
const Map<String, String> _assetByCodePrefix = <String, String>{
  'euclid': 'assets/images/euclid.png',
};

/// Araç tipine göre görsel yolu; tip bazlı görseller eklendikçe genişletilir.
const Map<String, String> _assetByType = <String, String>{
  'ROCK_TRUCK': 'assets/images/vehicle_default.png',
  'EXCAVATOR': 'assets/images/vehicle_default.png',
  'LOADER': 'assets/images/vehicle_default.png',
  'MIXER': 'assets/images/vehicle_default.png',
  'DOZER': 'assets/images/vehicle_default.png',
};

/// Araca ait görsel: önce taraflı görsel, sonra araç kodu, sonra tip, en sonda
/// varsayılan görsel. Yalnızca taraflı Euclid görsellerinde tekerlek bölgeleri
/// tanımlıdır; diğer görsellerde fotoğraf üzerinden seçim yapılamaz.
VehicleImageSpec vehicleImageSpec(
  Vehicle? vehicle, {
  VehicleImageSide side = VehicleImageSide.left,
}) {
  final String code = vehicle?.code ?? '';
  final bool right = side == VehicleImageSide.right;

  final String? euclidAsset = _euclidSideAsset(code, side);
  if (euclidAsset != null) {
    return VehicleImageSpec(
      asset: euclidAsset,
      aspectRatio: right ? _rightViewAspectRatio : _leftViewAspectRatio,
      // Euclid görsellerinin tuvalinde sağda geniş boşluk var; ortalanır.
      xShift: right ? 0 : _leftViewXShift,
      hotspots: right ? _euclidRightHotspots : _euclidLeftHotspots,
    );
  }

  final String? liugongAsset = _liugongSideAsset(code, side);
  if (liugongAsset != null) {
    // Liugong görselleri tuvale ortalanmış hazırlandığı için öteleme gerekmez.
    return VehicleImageSpec(
      asset: liugongAsset,
      aspectRatio: right ? _rightViewAspectRatio : _leftViewAspectRatio,
      hotspots: right ? _liugongRightHotspots : _liugongLeftHotspots,
    );
  }

  final String lower = code.toLowerCase();
  for (final MapEntry<String, String> entry in _assetByCodePrefix.entries) {
    if (lower.startsWith(entry.key)) {
      return VehicleImageSpec(asset: entry.value, xShift: _leftViewXShift);
    }
  }
  return VehicleImageSpec(
    asset: _assetByType[vehicle?.type] ?? 'assets/images/vehicle_default.png',
  );
}

/// Araca ait görselin yolu.
String vehicleImageAsset(
  Vehicle? vehicle, {
  VehicleImageSide side = VehicleImageSide.left,
}) =>
    vehicleImageSpec(vehicle, side: side).asset;

/// Sol görünüm görsellerinin tuvalinde sağ tarafta geniş bir şeffaf boşluk var
/// (1024 px'lik tuvalde solda ~13 px, sağda ~187 px). Bu yüzden araç kartın
/// solunda kalıyor; görsel kendi genişliğinin bu kadarı oranında sağa ötelenir.
/// Öteleme sırasında taşan kısım kırpılır, kırpılan alan zaten boştur.
const double _leftViewXShift = 0.085;

/// [asset] için yatay öteleme oranı (görsel genişliğinin katı).
/// Sağ (yansımalı) görsellerde tuval dengeli olduğu için öteleme yapılmaz.
double vehicleImageXShift(String asset) =>
    asset.startsWith('assets/images/sol/Euclid') ||
            asset == 'assets/images/euclid.png'
        ? _leftViewXShift
        : 0;

/// "Aracın Fotosu" alanı. Asset bulunamazsa vektörel kaya kamyonu çizimi gösterir,
/// böylece görsel dosyası eklenmeden de arayüz eksiksiz çalışır.
class VehiclePhoto extends StatelessWidget {
  const VehiclePhoto({
    super.key,
    required this.vehicle,
    this.showCaption = true,
    this.side = VehicleImageSide.left,
    this.onTireTap,
    this.hotspotColor,
  });

  final Vehicle? vehicle;
  final bool showCaption;

  /// Aracın gösterilecek tarafı (Lastik Değişimi ekranındaki Sol / Sağ seçimi).
  final VehicleImageSide side;

  /// Verilirse görseldeki tekerlekler tıklanabilir olur; geri çağrıya tekerleğin
  /// konum adı (ör. "Sol Arka Dış") gönderilir.
  final void Function(String position)? onTireTap;

  /// Tekerlek bölgelerinin vurgu rengi.
  final Color? hotspotColor;

  @override
  Widget build(BuildContext context) {
    final VehicleImageSpec spec = vehicleImageSpec(vehicle, side: side);

    final Widget image = Image.asset(
      spec.asset,
      fit: BoxFit.contain,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          const _MiningTruckArt(),
    );
    Widget photo = image;

    // Tekerlek bölgeleri görselle birlikte ölçeklensin diye görsel, tuvalin
    // en-boy oranındaki bir kutuya yerleştirilir.
    if (onTireTap != null && spec.aspectRatio != null && spec.hotspots.isNotEmpty) {
      final Color color = hotspotColor ?? Theme.of(context).colorScheme.primary;
      photo = AspectRatio(
        aspectRatio: spec.aspectRatio!,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;
            return Stack(
              children: <Widget>[
                Positioned.fill(child: image),
                for (final TireHotspot hotspot in spec.hotspots)
                  Positioned(
                    left: hotspot.rect.left * w,
                    top: hotspot.rect.top * h,
                    width: hotspot.rect.width * w,
                    height: hotspot.rect.height * h,
                    child: _TireHotspotButton(
                      position: hotspot.position,
                      color: color,
                      onTap: () => onTireTap!(hotspot.position),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    final double shift = spec.xShift;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: shift == 0
                  ? photo
                  : ClipRect(
                      child: FractionalTranslation(
                        translation: Offset(shift, 0),
                        child: photo,
                      ),
                    ),
            ),
          ),
          if (showCaption) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              vehicle?.code ?? 'Araç seçilmedi',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              vehicle == null
                  ? 'Listeden bir araç seçin'
                  : '${vehicle!.typeLabel} • ${vehicle!.tireCount} lastik',
              style: TextStyle(fontSize: 13, color: context.mutedColor),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Görsel üzerindeki şeffaf tekerlek butonu.
/// Dolgusu yoktur; yalnızca ince bir çerçeveyle tıklanabilir olduğu belli edilir.
class _TireHotspotButton extends StatelessWidget {
  const _TireHotspotButton({
    required this.position,
    required this.color,
    required this.onTap,
  });

  final String position;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(999);

    return Tooltip(
      message: position,
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          hoverColor: color.withValues(alpha: 0.22),
          splashColor: color.withValues(alpha: 0.28),
          highlightColor: color.withValues(alpha: 0.14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiningTruckArt extends StatelessWidget {
  const _MiningTruckArt();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 400 / 260,
      child: CustomPaint(painter: _MiningTruckPainter(dark: context.isDark)),
    );
  }
}

/// Referans görseldeki yeşil kaya kamyonunun sade vektörel karşılığı.
class _MiningTruckPainter extends CustomPainter {
  _MiningTruckPainter({required this.dark});

  final bool dark;

  static const Size _design = Size(400, 260);

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / _design.width;
    canvas.save();
    canvas.scale(scale);

    const Color body = Color(0xFF7CC242);
    const Color bodyDark = Color(0xFF5A9A26);
    const Color bodyLight = Color(0xFF9BD75F);
    const Color metal = Color(0xFF3C4349);
    const Color metalDark = Color(0xFF272C31);
    final Color glass = dark ? const Color(0xFF5C6B78) : const Color(0xFFBFD4E2);

    final Paint fill = Paint()..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = bodyDark;

    // Yer gölgesi
    fill.color = (dark ? Colors.black : const Color(0xFF1C1F23)).withValues(alpha: 0.08);
    canvas.drawOval(const Rect.fromLTWH(45, 218, 320, 26), fill);

    // Şasi
    fill.color = metal;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(60, 150, 292, 24), const Radius.circular(6)),
      fill,
    );

    // Damper (kasa) + kabin üstü koruma
    final Path bed = Path()
      ..moveTo(40, 48)
      ..lineTo(352, 48)
      ..lineTo(352, 76)
      ..lineTo(252, 76)
      ..lineTo(252, 152)
      ..lineTo(72, 152)
      ..lineTo(40, 112)
      ..close();
    fill.color = body;
    canvas.drawPath(bed, fill);
    canvas.drawPath(bed, stroke);

    // Kasa üst kenarı (açık yeşil vurgu)
    fill.color = bodyLight;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(40, 48, 312, 12), const Radius.circular(4)),
      fill,
    );

    // Kasa gövdesindeki yatay çizgiler
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = bodyDark.withValues(alpha: 0.55);
    canvas.drawLine(const Offset(62, 100), const Offset(248, 100), line);
    canvas.drawLine(const Offset(56, 126), const Offset(248, 126), line);

    // Kabin
    final RRect cab = RRect.fromRectAndRadius(
      const Rect.fromLTWH(256, 84, 92, 68),
      const Radius.circular(8),
    );
    fill.color = body;
    canvas.drawRRect(cab, fill);
    canvas.drawRRect(cab, stroke);

    // Cam
    fill.color = glass;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(266, 94, 72, 30), const Radius.circular(5)),
      fill,
    );

    // Ön ızgara ve farlar
    fill.color = metalDark;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(300, 130, 46, 22), const Radius.circular(4)),
      fill,
    );
    fill.color = const Color(0xFFF2F4F6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(306, 136, 14, 10), const Radius.circular(3)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(326, 136, 14, 10), const Radius.circular(3)),
      fill,
    );

    // Merdiven
    final Paint ladder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = metal;
    canvas.drawLine(const Offset(250, 118), const Offset(240, 172), ladder);
    for (int i = 0; i < 3; i++) {
      final double y = 128.0 + i * 14;
      canvas.drawLine(Offset(252 - i * 2.0, y), Offset(242 - i * 2.0, y), ladder);
    }

    // Tekerlekler
    _wheel(canvas, const Offset(120, 186), 46, metal, metalDark, body);
    _wheel(canvas, const Offset(308, 188), 42, metal, metalDark, body);

    canvas.restore();
  }

  void _wheel(Canvas canvas, Offset center, double r, Color tyre, Color tread, Color rim) {
    final Paint p = Paint()..style = PaintingStyle.fill;
    p.color = tread;
    canvas.drawCircle(center, r, p);
    p.color = tyre;
    canvas.drawCircle(center, r - 4, p);

    // Diş desenleri
    final Paint teeth = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = tread;
    for (int i = 0; i < 12; i++) {
      final double a = i * math.pi / 6;
      canvas.drawLine(
        center + Offset(r * 0.78 * math.cos(a), r * 0.78 * math.sin(a)),
        center + Offset(r * 0.98 * math.cos(a), r * 0.98 * math.sin(a)),
        teeth,
      );
    }

    p.color = rim;
    canvas.drawCircle(center, r * 0.45, p);
    p.color = tread;
    canvas.drawCircle(center, r * 0.16, p);
  }

  @override
  bool shouldRepaint(covariant _MiningTruckPainter oldDelegate) => oldDelegate.dark != dark;
}
