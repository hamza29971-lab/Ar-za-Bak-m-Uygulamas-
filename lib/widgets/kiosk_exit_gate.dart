import 'package:flutter/material.dart';

import '../services/kiosk_service.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import 'numeric_keypad.dart';
import 'result_dialog.dart';

/// Ekranın hangi kenarından kaydırıldığı.
enum _Edge { left, right, top, bottom }

/// Kenardan başlayan bir parmak hareketinin takibi.
class _EdgeDrag {
  _EdgeDrag(this.edge, this.start);

  final _Edge edge;
  final Offset start;
}

/// Kiosk modundan çıkış kapısı.
///
/// İki tetikleyici vardır:
///
///  1. **Kenardan kaydırma.** Kullanıcı uygulamadan çıkmak için ekranın
///     herhangi bir kenarından içeri doğru kaydırdığında parola penceresi
///     açılır. Kiosk kilidi bu hareketleri sisteme hiç ulaştırmadığı için
///     (ana ekran / son uygulamalar engelli) hareket burada yakalanır;
///     aksi halde kullanıcı hiçbir şey olmadığını görür ve tablette
///     sıkışıp kaldığını sanır.
///
///  2. **Gizli köşe.** Sol üst köşeye 3 saniye içinde 5 kez dokunmak da
///     aynı pencereyi açar. Kaydırma hareketi çalışmayan bir cihazda
///     yedek yoldur.
///
/// Parolalar Dart tarafında tutulmaz, Android'e doğrulatılır
/// (bkz. [KioskService]).
class KioskExitGate extends StatefulWidget {
  const KioskExitGate({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  /// Parola penceresi bu navigator üzerinden açılır. [MaterialApp.builder]
  /// içindeki context Navigator'un üstünde kaldığı için gereklidir.
  final GlobalKey<NavigatorState> navigatorKey;

  final Widget child;

  @override
  State<KioskExitGate> createState() => _KioskExitGateState();
}

class _KioskExitGateState extends State<KioskExitGate>
    with WidgetsBindingObserver {
  /// Gizli köşeyi açan dokunma sayısı ve süresi.
  static const int _requiredTaps = 5;
  static const Duration _tapWindow = Duration(seconds: 3);

  /// Köşenin dokunma alanı; görsel olarak hiçbir şey çizilmez.
  static const double _cornerSize = 90;

  /// Kaydırmanın "kenardan" sayılması için gereken yakınlık.
  static const double _edgeZone = 24;

  /// Parola penceresini açan en küçük içe kaydırma mesafesi.
  static const double _swipeThreshold = 48;

  int _taps = 0;
  DateTime? _firstTap;
  bool _dialogOpen = false;

  /// Kenardan kaydırma yalnızca tablet gerçekten kiosk modundayken
  /// dinlenir; aksi halde geliştirme sırasında her kenar hareketinde
  /// parola penceresi açılırdı.
  bool _kioskActive = false;

  /// Ekrandaki her parmak ayrı takip edilir.
  final Map<int, _EdgeDrag> _drags = <int, _EdgeDrag>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshKioskStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ayarlar'dan dönüşte veya kurtarma parolasından sonra durum değişir.
    if (state == AppLifecycleState.resumed) _refreshKioskStatus();
  }

  Future<void> _refreshKioskStatus() async {
    final KioskStatus status = await KioskService.instance.status();
    if (!mounted) return;
    if (status.deviceOwner != _kioskActive) {
      setState(() => _kioskActive = status.deviceOwner);
    }
  }

  // ------------------------------------------------------- gizli köşe

  void _onCornerTap() {
    final DateTime now = DateTime.now();
    final DateTime? first = _firstTap;

    if (first == null || now.difference(first) > _tapWindow) {
      _firstTap = now;
      _taps = 1;
      return;
    }

    _taps++;
    if (_taps < _requiredTaps) return;

    _taps = 0;
    _firstTap = null;
    _openPasswordDialog();
  }

  // -------------------------------------------------- kenardan kaydırma

  /// Dokunuşun başladığı kenar; kenara yakın değilse `null`.
  _Edge? _edgeOf(Offset position, Size size) {
    if (position.dx <= _edgeZone) return _Edge.left;
    if (position.dx >= size.width - _edgeZone) return _Edge.right;
    if (position.dy <= _edgeZone) return _Edge.top;
    if (position.dy >= size.height - _edgeZone) return _Edge.bottom;
    return null;
  }

  void _onPointerDown(PointerDownEvent event, Size size) {
    if (!_kioskActive || _dialogOpen) return;
    final _Edge? edge = _edgeOf(event.position, size);
    if (edge != null) _drags[event.pointer] = _EdgeDrag(edge, event.position);
  }

  void _onPointerMove(PointerMoveEvent event) {
    final _EdgeDrag? drag = _drags[event.pointer];
    if (drag == null) return;

    final Offset delta = event.position - drag.start;

    // Kenardan içe doğru alınan yol.
    final double inward = switch (drag.edge) {
      _Edge.left => delta.dx,
      _Edge.right => -delta.dx,
      _Edge.top => delta.dy,
      _Edge.bottom => -delta.dy,
    };

    // Kenar boyunca alınan yol. Liste kaydırması gibi kenara paralel
    // hareketler çıkış denemesi sayılmaz.
    final double lateral = switch (drag.edge) {
      _Edge.left || _Edge.right => delta.dy.abs(),
      _Edge.top || _Edge.bottom => delta.dx.abs(),
    };

    if (inward >= _swipeThreshold && inward > lateral) {
      _drags.remove(event.pointer);
      _openPasswordDialog();
    }
  }

  void _forgetPointer(PointerEvent event) => _drags.remove(event.pointer);

  // ------------------------------------------------------------ pencere

  Future<void> _openPasswordDialog() async {
    if (_dialogOpen) return;
    final BuildContext? context = widget.navigatorKey.currentContext;
    if (context == null) return;

    _dialogOpen = true;
    _drags.clear();
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (BuildContext context) => const KioskPasswordDialog(),
      );
    } finally {
      _dialogOpen = false;
      _refreshKioskStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    // Listener kullanılıyor, GestureDetector DEĞİL: ham işaretçi
    // olaylarını yalnızca İZLER, jest arenasına girmez. Böylece
    // altındaki listeler, butonlar ve kaydırmalar hiçbir şey
    // kaybetmeden çalışmaya devam eder.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent e) => _onPointerDown(e, size),
      onPointerMove: _onPointerMove,
      onPointerUp: _forgetPointer,
      onPointerCancel: _forgetPointer,
      child: Stack(
        children: <Widget>[
          widget.child,
          // Görünmez köşe. Altındaki arayüz çalışmaya devam etsin diye
          // yalnızca dokunmaları dinler, görsel olarak yer kaplamaz.
          Positioned(
            left: 0,
            top: 0,
            width: _cornerSize,
            height: _cornerSize,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _onCornerTap,
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kiosk çıkış parolası penceresi.
///
/// Parola tabletin sistem klavyesiyle DEĞİL, pencerenin kendi sayı
/// paneliyle girilir: kiosk modunda sistem klavyesi ekranın bir bölümünü
/// kaplayıp arayüzü bozabiliyor ve klavyedeki kısayollar kiosk'tan kaçış
/// yüzeyi oluşturuyor.
class KioskPasswordDialog extends StatefulWidget {
  const KioskPasswordDialog({super.key});

  @override
  State<KioskPasswordDialog> createState() => _KioskPasswordDialogState();
}

class _KioskPasswordDialogState extends State<KioskPasswordDialog> {
  /// Her iki parola da altı hanelidir; altıncı hane girilince kendiliğinden
  /// doğrulanır.
  static const int _length = 6;

  String _entry = '';
  String? _error;
  bool _busy = false;

  Color _tone(BuildContext context) => context.accent(AppColors.form);

  void _append(String digit) {
    if (_busy || _entry.length >= _length) return;
    setState(() {
      _entry += digit;
      _error = null;
    });
    if (_entry.length == _length) _submit();
  }

  void _backspace() {
    if (_busy || _entry.isEmpty) return;
    setState(() {
      _entry = _entry.substring(0, _entry.length - 1);
      _error = null;
    });
  }

  void _clear() {
    if (_busy || _entry.isEmpty) return;
    setState(() {
      _entry = '';
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final KioskUnlockResult result = await KioskService.instance.unlock(_entry);
    if (!mounted) return;

    switch (result) {
      case KioskUnlockResult.settings:
        // Ayarlar açıldı; pencere kapanır. Kullanıcı Ayarlar'dan
        // çıktığında tablet kendiliğinden uygulamaya döner.
        Navigator.of(context).pop();

      case KioskUnlockResult.released:
        Navigator.of(context).pop();
        await _showReleasedNotice();

      case KioskUnlockResult.invalid:
        setState(() {
          _busy = false;
          _entry = '';
          _error = 'Parola hatalı. Tekrar deneyin.';
        });

      case KioskUnlockResult.noOwner:
        setState(() {
          _busy = false;
          _entry = '';
          _error = 'Tablet kiosk modunda değil; çıkış gerekmiyor.';
        });

      case KioskUnlockResult.failed:
        setState(() {
          _busy = false;
          _entry = '';
          _error = 'İşlem tamamlanamadı. Yetkiliye bildirin.';
        });
    }
  }

  Future<void> _showReleasedNotice() async {
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    await showResultDialog(
      navigator.context,
      title: 'Kiosk Koruması Kaldırıldı',
      subtitle: formatDateTime(DateTime.now()),
      icon: Icons.lock_open,
      accent: AppColors.form,
      details: <String, String>{
        'Cihaz sahipliği': 'Bırakıldı',
        'Uygulama kaldırma': 'Açık',
        'Fabrika ayarlarına sıfırlama': 'Açık',
      },
      note: 'Tableti yeniden kiosk moduna almak için kurulum scripti '
          '(nimobakim-tablet-kur.bat) baştan çalıştırılmalıdır.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color tone = _tone(context);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _header(context, tone),
            Divider(height: 1, color: context.borderColor),
            // Dusuk cozunurluklu tablette (ör. 1024x600) pencere ekrana
            // sigmayabilir; tasma yerine kaydirilir.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 6),
                child: Column(
                  children: <Widget>[
                    _dots(context, tone),
                    const SizedBox(height: 10),
                    _errorLine(context),
                    const SizedBox(height: 14),
                    NumericKeypad(
                      enabled: !_busy,
                      onDigit: _append,
                      onBackspace: _backspace,
                      onClear: _clear,
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: context.borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 18),
                    ),
                    child: Text(
                      'Vazgeç',
                      style: TextStyle(
                          fontSize: 16, color: context.mutedColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Color tone) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: context.isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.lock_outline, color: tone, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Yetkili Girişi',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  'Uygulamadan çıkmak için 6 haneli parolayı girin',
                  style: TextStyle(fontSize: 14, color: context.mutedColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Girilen hane sayısını gösteren noktalar.
  Widget _dots(BuildContext context, Color tone) {
    final bool hasError = _error != null;
    final Color filled = hasError ? context.accent(AppColors.emergency) : tone;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < _length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _entry.length ? filled : Colors.transparent,
                border: Border.all(
                  color: i < _entry.length ? filled : context.borderColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Hata satırı; yer her zaman ayrılır ki panel zıplamasın.
  Widget _errorLine(BuildContext context) {
    return SizedBox(
      height: 20,
      child: _busy
          ? Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _tone(context)),
              ),
            )
          : Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.accent(AppColors.emergency),
              ),
            ),
    );
  }
}
