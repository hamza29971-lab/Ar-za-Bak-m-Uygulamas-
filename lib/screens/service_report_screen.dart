import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../services/publish_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/common.dart';
import '../widgets/nimo_page.dart';
import '../widgets/result_dialog.dart';
import '../widgets/vehicle_selector.dart';

/// Gönderilen raporun türü. Ekran başına sabittir; kullanıcı seçmez.
enum ReportType {
  /// "Servis Raporu" ekranının tek türü.
  general('Servis Raporu', Icons.assignment_outlined),

  /// "Mekanik Operasyon" ekranının tek türü.
  mechanical('Mekanik Operasyon', Icons.build_outlined);

  const ReportType(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// "Servis Raporu" ekranı: araç seçimi + görsel(ler) + açıklama.
///
/// Aynı ekran "Mekanik Operasyon" sekmesinde de kullanılır; tek fark [type]
/// ve başlıktır.
class ServiceReportScreen extends StatefulWidget {
  const ServiceReportScreen({
    super.key,
    this.title = 'Servis Raporu',
    this.type = ReportType.general,
    this.accent = AppColors.form,
    this.allowGallery = true,
    this.showServiceHours = true,
  });

  /// Sayfa başlığı.
  final String title;

  /// Bu ekrandan gönderilen raporun türü.
  final ReportType type;

  /// Ekranın vurgu rengi; sekme rengiyle aynı olmalıdır.
  final Color accent;

  /// Galeriden/dosyadan görsel seçmeye izin verilsin mi. "Servis Raporu" ve
  /// "Mekanik Operasyon" sekmelerinde kapalıdır: oralarda görsel yalnızca
  /// kamerayla eklenebilir.
  final bool allowGallery;

  /// Servisin başlangıç / bitiş saati alanları gösterilsin mi. "Servis
  /// Raporu" sekmesinde açıktır.
  final bool showServiceHours;

  @override
  State<ServiceReportScreen> createState() => _ServiceReportScreenState();
}

class _ServiceReportScreenState extends State<ServiceReportScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _description = TextEditingController();
  final List<XFile> _images = <XFile>[];

  /// Servisin başlangıç ve bitiş saati; seçilmemişse null.
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _sending = false;

  Color get accent => widget.accent;

  /// Kenarlıklar her iki rapor ekranında da aynı mavi tonda. Modül rengi
  /// Kullanıldığı sekmenin (Servis Raporu veya Mekanik Operasyon) ana rengini
  /// kenarlıklarda da kullanır. Böylece Mekanik Operasyon tamamen sarı olur.
  Color get borderAccent => accent;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- görseller

  Future<void> _pickImages() async {
    try {
      final int remaining = 5 - _images.length;
      if (remaining <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En fazla 5 fotoğraf eklenebilir.')),
        );
        return;
      }
      final List<XFile> picked = await _picker.pickMultiImage(
        imageQuality: 50,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked.isEmpty) return;
      setState(() => _images.addAll(picked.take(remaining)));
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel seçilemedi: $e')),
      );
    }
  }

  /// Masaüstünde `image_picker` kamerayı desteklemez (hata fırlatır); saha
  /// tabletlerinde çalışır. Kullanıcı bunu bir arıza sanmasın diye ayrı mesaj.
  static bool get _desktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  Future<void> _takePhoto() async {
    try {
      if (_images.length >= 5) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En fazla 5 fotoğraf eklenebilir.')),
        );
        return;
      }
      final XFile? shot = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (shot == null) return;
      setState(() => _images.add(shot));
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_desktop
              ? (widget.allowGallery
                  ? 'Masaüstünde kamera kullanılamıyor. Fotoğraf çekmek için '
                      'uygulamayı tablette çalıştırın; buradan "Görsel Ekle" '
                      'ile dosya seçebilirsiniz.'
                  : 'Masaüstünde kamera kullanılamıyor. Fotoğraf çekmek için '
                      'uygulamayı tablette çalıştırın.')
              : 'Kamera kullanılamadı: $e'),
        ),
      );
    }
  }

  // ------------------------------------------------------------------ saatler

  /// Saat her yerde 24 saat biçiminde ("08:30") gösterilir.
  static String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  /// Kadranlı `showTimePicker` yerine saat ve dakikanın listeden seçildiği
  /// pencere açılır; saha ekipleri için okunması ve dokunması daha kolay.
  Future<void> _pickTime({required bool isStart}) async {
    // Saat seçimi sırasında açıklama alanına odak geçmemesi için önce klavyeyi kapat
    FocusManager.instance.primaryFocus?.unfocus();
    final TimeOfDay? picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) => _TimeListPicker(
        title: isStart ? 'Başlangıç saatini seçin' : 'Bitiş saatini seçin',
        initial: isStart ? _startTime : _endTime,
        accent: accent,
      ),
    );
    if (picked == null) return;
    // Seçim sonrasında klavyenin açılmaması için odaklamayı temizle
    if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  // ------------------------------------------------------------------ gönder

  void _showValidationPopup(List<String> errors) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.info_outline_rounded, color: accent, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Lütfen Tüm Alanları Doldurun',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'İşlemi tamamlayıp raporu gönderebilmemiz için aşağıdaki bilgileri de seçmeniz/yazmanız gerekiyor:',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ...errors.map((String e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          Expanded(child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Tamam'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _send() async {
    final AppState state = AppScope.read(context);
    final Vehicle? vehicle = state.selectedVehicle;

    final List<String> errors = [];

    if (vehicle == null) {
      errors.add('Araç seçimi yapmadınız.');
    }

    if (widget.showServiceHours) {
      if (_startTime == null) {
        errors.add('Başlangıç saatini seçmediniz.');
      }
      if (_endTime == null) {
        errors.add('Bitiş saatini seçmediniz.');
      }
      // Saat mantık kontrolü seçim anında yapılıyor, burada tekrar kontrol gerekmez
    }

    if (_images.isEmpty) {
      errors.add('Hiç fotoğraf eklemediniz (En az 1 fotoğraf zorunludur).');
    }

    if (_description.text.trim().isEmpty) {
      errors.add('Açıklama alanını boş bıraktınız.');
    }

    if (errors.isNotEmpty) {
      _showValidationPopup(errors);
      return;
    }

    final List<String> imagePaths = _images.map((XFile f) => f.path).toList();
    // Servis saatleri yalnızca alanların gösterildiği ekranda anlamlıdır.
    // Mekanik Operasyon'da bu alanlar kapalı olduğu için saat bilgisi hiç
    // gönderilmez; koşul bunu yerleşimden bağımsız olarak garanti eder.
    final String? startText = widget.showServiceHours && _startTime != null
        ? _formatTime(_startTime!)
        : null;
    final String? endText = widget.showServiceHours && _endTime != null
        ? _formatTime(_endTime!)
        : null;
    final String hours = startText == null && endText == null
        ? ''
        : '${startText ?? '-'} - ${endText ?? '-'}';

    setState(() => _sending = true);
    final PublishResult result = await PublishService.instance.publishReport(
      state: state,
      reportType: widget.type.label,
      description: _description.text.trim(),
      imagePaths: imagePaths,
      items: const <Map<String, Object?>>[],
      vehicleCode: vehicle?.code,
      userRegistryNo: state.user?.registryNo,
      startTime: startText,
      endTime: endText,
    );
    if (!mounted) return;
    setState(() => _sending = false);

    // Gönderim başarısızsa form korunur: kullanıcı düzeltip tekrar dener.
    if (!result.success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            'Gönderilemedi: ${result.error ?? 'bilinmeyen hata'}',
          ),
        ));
      return;
    }

    final DateTime sentAt = DateTime.now();
    state.addActivity(
      ServiceReportActivity(
        id: 'rapor-${sentAt.microsecondsSinceEpoch}',
        vehicleCode: vehicle?.code ?? '',
        date: sentAt,
        reportType: widget.type.label,
        description: _description.text.trim(),
        imagePaths: imagePaths,
        itemCount: 0,
      ),
    );
    state.addNotification(
      NotificationItem(
        title: 'Servis raporu gönderildi',
        message: '${widget.type.label} • ${imagePaths.length} görsel'
            '${vehicle != null ? ' • ${vehicle.code}' : ''}'
            '${hours.isEmpty ? '' : ' • $hours'}',
        date: sentAt,
        kind: NotificationKind.form,
        vehicleCode: vehicle?.code,
        details: <String, String>{
          'Rapor türü': widget.type.label,
          'Başlangıç saati': ?startText,
          'Bitiş saati': ?endText,
          'Gönderilen görsel': '${imagePaths.length}',
          'Açıklama': _description.text.trim(),
          'Gönderim tarihi': formatDateTime(sentAt),
        },
      ),
    );

    await showResultDialog(
      context,
      title: 'Rapor gönderildi',
      subtitle: formatDateTime(sentAt),
      details: <String, String>{
        'Rapor türü': widget.type.label,
        'Araç': vehicle?.code ?? '-',
        if (widget.showServiceHours)
          'Servis saati': hours.isEmpty ? '-' : hours,
        'Gönderilen görsel': '${imagePaths.length} adet',
      },
    );

    if (!mounted) return;
    setState(() {
      _images.clear();
      _description.clear();
      _startTime = null;
      _endTime = null;
    });
  }

  // ------------------------------------------------------------------ arayüz

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final Vehicle? vehicle = state.selectedVehicle;

    return NimoPage(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PageHeading(
                title: widget.title,
                subtitle: 'Aracı seçin, görsel ve açıklama ile gönderin',
              ),
              const SizedBox(height: 16),
              // Araç listeden seçilir; seçim diğer ekranlarla ortaktır.
              // Servis saatleri aynı satırın sağında durur, dar ekranda alta
              // iner.
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: <Widget>[
                    VehicleSelector(
                      selected: vehicle,
                      accentColor: accent,
                      borderAccent: borderAccent,
                      width: 360,
                      onSelected: state.selectVehicle,
                    ),
                    if (widget.showServiceHours) _buildServiceHours(context),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400,
                child: _buildCards(context),
              ),
              const SizedBox(height: 20),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Servisin başlangıç ve bitiş saati alanları.
  Widget _buildServiceHours(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        _buildTimeField(
          context,
          label: 'Başlangıç Saati',
          value: _startTime,
          onTap: () => _pickTime(isStart: true),
        ),
        _buildTimeField(
          context,
          label: 'Bitiş Saati',
          value: _endTime,
          onTap: () => _pickTime(isStart: false),
        ),
      ],
    );
  }

  /// Tıklanınca saat seçiciyi açan, araç seçici ile aynı görünümde alan.
  Widget _buildTimeField(
    BuildContext context, {
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    final bool isSet = value != null;
    return SizedBox(
      width: 200,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            // Metin alanlarıyla aynı dolgu; koyu temada zeminden ayrışır.
            color: context.isDark ? context.cardColor : context.pageColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSet ? accent : context.moduleBorderColor(accent), width: 2.5),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.schedule_outlined,
                  size: 20, color: isSet ? accent : context.mutedColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label,
                        style: TextStyle(
                            fontSize: 11, color: context.isDark ? Colors.white : context.mutedColor)),
                    const SizedBox(height: 2),
                    Text(
                      isSet ? _formatTime(value) : 'Saat seçin',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.isDark ? Colors.white : (isSet ? null : context.mutedColor),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_down,
                  size: 20, color: context.mutedColor),
            ],
          ),
        ),
      ),
    );
  }

  /// Görsel ve açıklama kartları.
  Widget _buildCards(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: _buildImageCard(context)),
        const SizedBox(width: 20),
        Expanded(child: _buildDescriptionCard(context)),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        if (_images.isNotEmpty ||
            _description.text.isNotEmpty ||
            _startTime != null ||
            _endTime != null)
          TextButton.icon(
            onPressed: _sending
                ? null
                : () => setState(() {
                      _images.clear();
                      _description.clear();
                      _startTime = null;
                      _endTime = null;
                    }),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Raporu temizle'),
          ),
        const SizedBox(width: 12),
        SizedBox(
          width: 260,
          child: FilledButton.icon(
            onPressed: _sending ? null : _send,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              minimumSize: const Size(0, 56),
            ),
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send),
            label: Text(_sending ? 'Gönderiliyor...' : 'Raporu Gönder'),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(BuildContext context) {
    return SectionCard(
      title: 'Rapor Görselleri',
      icon: Icons.image_outlined,
      accent: accent,
      borderAccent: borderAccent,
      expandChild: true,
      trailing: Text('${_images.length} görsel',
          style: TextStyle(fontSize: 13, color: context.mutedColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (widget.allowGallery) ...<Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _pickImages,
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Görsel Ekle'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Fotoğraf Çek'),
                  ),
                ),
              ] else
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _takePhoto,
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Fotoğraf Çek'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _images.isEmpty
                ? _buildDropHint(context)
                : GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: _images.length,
                    itemBuilder: (BuildContext context, int i) =>
                        _buildThumb(context, i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropHint(BuildContext context) {
    // Yer varsa ortalanır, dar ekranda (rapor tablosu da açıkken) kayar.
    return DottedBorderBox(
      accent: borderAccent,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.cloud_upload_outlined, size: 40, color: context.mutedColor),
                  const SizedBox(height: 12),
                  Text('Henüz görsel eklenmedi',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: context.mutedColor)),
                  const SizedBox(height: 6),
                  Text(
                      widget.allowGallery
                          ? 'Birden fazla görsel seçebilirsiniz.'
                          : 'Fotoğraf çekerek görsel ekleyebilirsiniz.',
                      style: TextStyle(fontSize: 13, color: context.mutedColor)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThumb(BuildContext context, int index) {
    final XFile file = _images[index];
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (kIsWeb)
            Image.network(file.path, fit: BoxFit.cover)
          else
            Image.file(File(file.path), fit: BoxFit.cover,
                errorBuilder: (BuildContext c, Object e, StackTrace? s) {
              return Container(
                color: context.cardColor,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              );
            }),
          Positioned(
            right: 6,
            top: 6,
            child: InkWell(
              onTap: () => setState(() => _images.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 15, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    return SectionCard(
      title: 'Açıklama',
      icon: Icons.edit_note_outlined,
      accent: accent,
      borderAccent: borderAccent,
      expandChild: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _description,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Rapor ile ilgili açıklamayı buraya yazın...',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('${_description.text.trim().length} karakter',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: context.mutedColor)),
        ],
      ),
    );
  }
}

/// Kesikli çerçeveli boş alan kutusu.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child, required this.accent});

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.moduleBorderColor(accent), width: 2.5),
      ),
      child: child,
    );
  }
}


/// Saat ve dakikanın iki ayrı listeden seçildiği 24 saatlik seçici.
///
/// Seçim yapılınca [TimeOfDay] ile, vazgeçilince `null` ile kapanır.
class _TimeListPicker extends StatefulWidget {
  const _TimeListPicker({
    required this.title,
    required this.initial,
    required this.accent,
  });

  final String title;

  /// Alanda hâlihazırda seçili olan saat; yoksa liste seçimsiz açılır.
  final TimeOfDay? initial;

  final Color accent;

  @override
  State<_TimeListPicker> createState() => _TimeListPickerState();
}

class _TimeListPickerState extends State<_TimeListPicker> {
  static const double _rowHeight = 44;
  static const double _listHeight = 264; // 6 satır

  late int? _hour = widget.initial?.hour;
  late int? _minute = widget.initial?.minute;

  late final ScrollController _hourScroll =
      ScrollController(initialScrollOffset: _offsetFor(_hour, 24));
  late final ScrollController _minuteScroll =
      ScrollController(initialScrollOffset: _offsetFor(_minute, 60));

  /// Seçili satır açılışta ortada görünsün; liste sınırlarının dışına taşmaz.
  static double _offsetFor(int? value, int count) {
    if (value == null) return 0;
    final double maxOffset = count * _rowHeight - _listHeight;
    if (maxOffset <= 0) return 0;
    final double target = value * _rowHeight - (_listHeight - _rowHeight) / 2;
    if (target < 0) return 0;
    return target > maxOffset ? maxOffset : target;
  }

  @override
  void dispose() {
    _hourScroll.dispose();
    _minuteScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool complete = _hour != null && _minute != null;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 300,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildColumn(
              context,
              label: 'Saat',
              count: 24,
              selected: _hour,
              controller: _hourScroll,
              onSelected: (int v) => setState(() => _hour = v),
            ),
            const SizedBox(width: 16),
            _buildColumn(
              context,
              label: 'Dakika',
              count: 60,
              selected: _minute,
              controller: _minuteScroll,
              onSelected: (int v) => setState(() => _minute = v),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          // İkisi de seçilmeden saat oluşturulamaz.
          onPressed: complete
              ? () => Navigator.of(context)
                  .pop(TimeOfDay(hour: _hour!, minute: _minute!))
              : null,
          child: const Text('Tamam'),
        ),
      ],
    );
  }

  Widget _buildColumn(
    BuildContext context, {
    required String label,
    required int count,
    required int? selected,
    required ScrollController controller,
    required ValueChanged<int> onSelected,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 12, color: context.mutedColor)),
        const SizedBox(height: 6),
        Container(
          width: 120,
          height: _listHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.moduleBorderColor(widget.accent), width: 2.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Scrollbar(
            controller: controller,
            thumbVisibility: true,
            child: ListView.builder(
              controller: controller,
              padding: EdgeInsets.zero,
              itemExtent: _rowHeight,
              itemCount: count,
              itemBuilder: (BuildContext context, int i) {
                final bool isSelected = i == selected;
                return InkWell(
                  onTap: () => onSelected(i),
                  child: Container(
                    alignment: Alignment.center,
                    color: isSelected ? widget.accent : null,
                    child: Text(
                      i.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
