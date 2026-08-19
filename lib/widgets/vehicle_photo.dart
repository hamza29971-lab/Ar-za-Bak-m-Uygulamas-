import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Aracın hangi tarafının gösterileceği.
/// "Lastik Değişimi" ekranındaki Sol / Sağ seçimi bu değeri belirler;
/// diğer ekranlar sol görünümü kullanır.
enum VehicleImageSide { left, right }

/// Taraflı görseli bulunan Euclid araçları (`Euclid-1` … `Euclid-11`),
/// Liugong maden kamyonları (`Liugong-16` … `Liugong-20`) ve Liugong loderler
/// (`Liugong-33` … `Liugong-39`). Bunların dışındaki araçlar genel görsele düşer.
const int _euclidSideImageCount = 11;
const int _liugongFirstTruck = 16;
const int _liugongLastTruck = 20;
const int _liugongFirstLoader = 33;
const int _liugongLastLoader = 39;

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

/// Liugong araçlarının taraflı görsel yolu:
/// sol -> `assets/images/sol/Liugong[N].png`,
/// sağ -> `assets/images/sağ/Liugong[N]yansıma.png`.
String _liugongAsset(int number, VehicleImageSide side) =>
    side == VehicleImageSide.right
        ? 'assets/images/sağ/Liugong${number}yansıma.png'
        : 'assets/images/sol/Liugong$number.png';

/// Liugong maden kamyonlarının (10 lastik) görselleri.
String? _liugongTruckSideAsset(String code, VehicleImageSide side) {
  final int? number = _vehicleNumber(code, 'liugong');
  if (number == null || number < _liugongFirstTruck || number > _liugongLastTruck) {
    return null;
  }
  return _liugongAsset(number, side);
}

/// Liugong loderlerin (4 lastik) görselleri.
String? _liugongLoaderSideAsset(String code, VehicleImageSide side) {
  final int? number = _vehicleNumber(code, 'liugong');
  if (number == null ||
      number < _liugongFirstLoader ||
      number > _liugongLastLoader) {
    return null;
  }
  return _liugongAsset(number, side);
}

/// Euclid görsellerinin en-boy oranları (tuval ölçüleri sabit).
const double _leftViewAspectRatio = 1024 / 572;
const double _rightViewAspectRatio = 1024 / 660;

/// Loder görsellerinin tuval oranı; iki taraf da aynı ölçüde hazırlanmıştır.
const double _loaderAspectRatio = 1024 / 659;

/// Görsel üzerindeki tıklanabilir tekerlek bölgesi.
/// [rect] görselin sol üst köşesine göre 0..1 aralığında normalize edilmiştir;
/// [position] araç tanımındaki konum adıyla birebir aynı olmalıdır.
///
/// İkili (yan yana) tekerlekler için [TireHotspot.pair] kullanılır: iki tekerlek
/// tek bir bölgeyle temsil edilir, tıklanınca kullanıcı "İç" / "Dış" seçer.
/// Böylece parmakla yanlış tekerleğe basma riski ortadan kalkar.
@immutable
class TireHotspot {
  /// Tek bir tekerleğe karşılık gelen bölge.
  const TireHotspot(this.position, this.rect) : pairedPosition = null;

  /// Yan yana duran iki tekerleği kapsayan tek bölge. [position] içteki,
  /// [pairedPosition] dıştaki tekerlektir.
  const TireHotspot.pair(this.position, this.pairedPosition, this.rect);

  /// Tek tekerlekli bölgelerde tekerleğin konumu; ikili bölgelerde içteki.
  final String position;

  /// İkili bölgede dıştaki tekerleğin konumu; tek tekerlekli bölgede `null`.
  final String? pairedPosition;

  final Rect rect;

  /// Bölge yan yana iki tekerleği mi kapsıyor?
  bool get isPair => pairedPosition != null;

  /// Bölgenin kapsadığı konumlar (ikili bölgede iç, dış sırasıyla).
  List<String> get positions => pairedPosition == null
      ? <String>[position]
      : <String>[position, pairedPosition!];

  /// İkili bölgenin ortak adı: "Sol Arka İç" -> "Sol Arka".
  String get groupLabel {
    final int cut = position.lastIndexOf(' ');
    return cut <= 0 ? position : position.substring(0, cut);
  }

  /// Konumun ayırt edici son sözcüğü: "Sol Arka İç" -> "İç".
  static String choiceLabelOf(String position) {
    final int cut = position.lastIndexOf(' ');
    return cut < 0 ? position : position.substring(cut + 1);
  }
}

/// Euclid sol görünümünde görünen tekerlekler: ön tekerlek tek, arkadaki ikili
/// tekerlekler tek bölgede birleştirilmiştir.
const List<TireHotspot> _euclidLeftHotspots = <TireHotspot>[
  TireHotspot('Sol Ön', Rect.fromLTRB(0.335, 0.555, 0.550, 0.990)),
  TireHotspot.pair(
    'Sol Arka İç',
    'Sol Arka Dış',
    Rect.fromLTRB(0.590, 0.550, 0.765, 0.930),
  ),
];

/// Euclid sağ (yansımalı) görünümünde görünen tekerlekler.
const List<TireHotspot> _euclidRightHotspots = <TireHotspot>[
  TireHotspot('Sağ Ön', Rect.fromLTRB(0.365, 0.530, 0.590, 0.950)),
  TireHotspot.pair(
    'Sağ Arka İç',
    'Sağ Arka Dış',
    Rect.fromLTRB(0.130, 0.555, 0.355, 0.930),
  ),
];

/// Liugong sol görünümünde görünen tekerlekler (ön aks + ikili orta ve arka
/// akslar). İkili akslarda dıştaki tekerlek tam görünür, içteki onun arkasında
/// kalır; ikisi tek bölgede birleştirilip seçim menüsüyle ayrıştırılır.
const List<TireHotspot> _liugongLeftHotspots = <TireHotspot>[
  TireHotspot('Sol Ön', Rect.fromLTRB(0.480, 0.600, 0.640, 0.985)),
  TireHotspot.pair(
    'Sol Orta İç',
    'Sol Orta Dış',
    Rect.fromLTRB(0.686, 0.640, 0.786, 0.935),
  ),
  TireHotspot.pair(
    'Sol Arka İç',
    'Sol Arka Dış',
    Rect.fromLTRB(0.786, 0.650, 0.858, 0.925),
  ),
];

/// Liugong sağ (yansımalı) görünümünde görünen tekerlekler.
const List<TireHotspot> _liugongRightHotspots = <TireHotspot>[
  TireHotspot('Sağ Ön', Rect.fromLTRB(0.355, 0.615, 0.510, 0.985)),
  TireHotspot.pair(
    'Sağ Orta İç',
    'Sağ Orta Dış',
    Rect.fromLTRB(0.165, 0.660, 0.268, 0.925),
  ),
  TireHotspot.pair(
    'Sağ Arka İç',
    'Sağ Arka Dış',
    Rect.fromLTRB(0.085, 0.665, 0.165, 0.925),
  ),
];

/// Liugong loderlerin sol görünümünde görünen tekerlekler. Loderde her köşede
/// tek teker vardır; ikili bölgeye (iç/dış seçimine) gerek yoktur.
/// Kepçe solda kaldığı için öndeki tekerlek görselin ortasına yakındır.
const List<TireHotspot> _loaderLeftHotspots = <TireHotspot>[
  TireHotspot('Sol Ön', Rect.fromLTRB(0.651, 0.470, 0.813, 0.880)),
  TireHotspot('Sol Arka', Rect.fromLTRB(0.871, 0.504, 0.986, 0.835)),
];

/// Liugong loderlerin sağ (yansımalı) görünümündeki tekerlekler.
const List<TireHotspot> _loaderRightHotspots = <TireHotspot>[
  TireHotspot('Sağ Ön', Rect.fromLTRB(0.187, 0.470, 0.349, 0.880)),
  TireHotspot('Sağ Arka', Rect.fromLTRB(0.014, 0.504, 0.129, 0.835)),
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

  final String? liugongAsset = _liugongTruckSideAsset(code, side);
  if (liugongAsset != null) {
    // Liugong görselleri tuvale ortalanmış hazırlandığı için öteleme gerekmez.
    return VehicleImageSpec(
      asset: liugongAsset,
      aspectRatio: right ? _rightViewAspectRatio : _leftViewAspectRatio,
      hotspots: right ? _liugongRightHotspots : _liugongLeftHotspots,
    );
  }

  final String? loaderAsset = _liugongLoaderSideAsset(code, side);
  if (loaderAsset != null) {
    return VehicleImageSpec(
      asset: loaderAsset,
      aspectRatio: _loaderAspectRatio,
      hotspots: right ? _loaderRightHotspots : _loaderLeftHotspots,
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
                      hotspot: hotspot,
                      color: color,
                      onSelected: onTireTap!,
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

const Duration _tooltipDelay = Duration(milliseconds: 400);

/// Görsel üzerindeki şeffaf tekerlek butonu.
///
/// Tek tekerlekli bölgede dokunuş doğrudan o tekerleği açar. İkili bölgede
/// (yan yana iki tekerlek) önce "İç" / "Dış" menüsü açılır; iki küçük buton
/// yerine tek büyük bölge kullanıldığı için yanlış tekerleğe basılamaz.
class _TireHotspotButton extends StatelessWidget {
  const _TireHotspotButton({
    required this.hotspot,
    required this.color,
    required this.onSelected,
  });

  final TireHotspot hotspot;
  final Color color;
  final void Function(String position) onSelected;

  @override
  Widget build(BuildContext context) {
    if (!hotspot.isPair) {
      return Tooltip(
        message: hotspot.position,
        waitDuration: _tooltipDelay,
        child: _HotspotOutline(
          color: color,
          onTap: () => onSelected(hotspot.position),
        ),
      );
    }

    return Tooltip(
      message: '${hotspot.groupLabel} — iç / dış seçin',
      waitDuration: _tooltipDelay,
      child: MenuAnchor(
        alignmentOffset: const Offset(0, 6),
        menuChildren: <Widget>[
          for (final String position in hotspot.positions)
            _TireChoiceItem(
              position: position,
              color: color,
              onPressed: () => onSelected(position),
            ),
        ],
        builder: (
          BuildContext context,
          MenuController controller,
          Widget? child,
        ) =>
            _HotspotOutline(
          color: color,
          hasChoices: true,
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }
}

/// Tekerlek bölgesinin çerçevesi. Dolgusu yoktur; yalnızca ince bir çerçeveyle
/// tıklanabilir olduğu belli edilir. [hasChoices] ise altına, menü açılacağını
/// belirten küçük bir ok rozeti eklenir.
class _HotspotOutline extends StatelessWidget {
  const _HotspotOutline({
    required this.color,
    required this.onTap,
    this.hasChoices = false,
  });

  final Color color;
  final VoidCallback onTap;
  final bool hasChoices;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(999);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        hoverColor: color.withValues(alpha: 0.22),
        splashColor: color.withValues(alpha: 0.28),
        highlightColor: color.withValues(alpha: 0.14),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border:
                      Border.all(color: color.withValues(alpha: 0.55), width: 2),
                ),
              ),
            ),
            if (hasChoices)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 3),
                  width: 26,
                  height: 16,
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withValues(alpha: 0.55)),
                  ),
                  child: Icon(Icons.expand_more, size: 13, color: color),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// İkili tekerlek bölgesine dokunulunca açılan menüdeki seçenek:
/// büyük "İç" / "Dış" etiketi ve altında tam konum adı.
class _TireChoiceItem extends StatelessWidget {
  const _TireChoiceItem({
    required this.position,
    required this.color,
    required this.onPressed,
  });

  final String position;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      onPressed: onPressed,
      leadingIcon: Icon(Icons.trip_origin, size: 20, color: color),
      child: Padding(
        // Tablette parmakla rahat seçilebilsin diye satır yüksek tutulur.
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                TireHotspot.choiceLabelOf(position),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                position,
                style: TextStyle(fontSize: 12, color: context.mutedColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Görsel bulunamadığında gösterilen vektörel kaya kamyonu çizimi.
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
