import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// NIMO robot logosu.
///
/// `assets/images/nimo_logo.png` varsa o kullanılır; yoksa aynı hisse sahip
/// vektörel bir robot simgesi gösterilir. Böylece görsel dosyası eklenmeden de
/// arayüz eksiksiz çalışır.
class NimoLogo extends StatelessWidget {
  const NimoLogo({super.key, this.size = 44, this.background = true});

  final double size;
  final bool background;

  static const String asset = 'assets/images/nimo_logo.png';

  @override
  Widget build(BuildContext context) {
    // Arkaplan kutusu varken görsel, kutunun içinde kalacak kadar küçültülür;
    // aksi halde kutu boyutunda çizilip taşardı.
    final double imageSize = background ? size * 0.88 : size;

    final Widget image = Image.asset(
      asset,
      width: imageSize,
      height: imageSize,
      fit: BoxFit.contain,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) => Icon(
        Icons.smart_toy_outlined,
        size: size * 0.55,
        color: context.brandColor,
      ),
    );

    if (!background) return SizedBox(width: size, height: size, child: image);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.brandSoftColor,
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: image,
    );
  }
}
