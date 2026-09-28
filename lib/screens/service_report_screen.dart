import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../services/publish_service.dart';
import '../services/fleet_event_client.dart';
import '../services/service_locator.dart';
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

class _ServiceCartItem {
  final Vehicle vehicle;
  final List<XFile> images;
  final String description;
  final String? serviceType;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  _ServiceCartItem({
    required this.vehicle,
    required this.images,
    required this.description,
    this.serviceType,
    this.startTime,
    this.endTime,
  });
}

class _ServiceReportScreenState extends State<ServiceReportScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _description = TextEditingController();
  final List<XFile> _images = <XFile>[];

  /// Servisin başlangıç ve bitiş saati; seçilmemişse null.
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  String? _selectedService;
  List<String> _fetchedServices = [];
  bool _fetchingServices = false;

  final List<_ServiceCartItem> _cart = [];

  @override
  void initState() {
    super.initState();
  }
  int? _editingIndex;

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
        minTime: isStart ? null : _startTime,
      ),
    );
    if (picked == null) return;
    // Seçim sonrasında klavyenin açılmaması için odaklamayı temizle
    if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      if (isStart) {
        _startTime = picked;
        // Eğer başlangıç saati değiştiyse ve mevcut bitiş saati başlangıçtan önce kaldıysa sıfırla
        if (_endTime != null) {
          final int startMins = _startTime!.hour * 60 + _startTime!.minute;
          final int endMins = _endTime!.hour * 60 + _endTime!.minute;
          if (startMins >= endMins) {
            _endTime = null;
          }
        }
      } else {
        _endTime = picked;
      }
    });
  }

  // ------------------------------------------------------------------ sepet fonksiyonları
  Future<void> _pickService() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final AppState state = AppScope.read(context);
    final vehicle = state.selectedVehicle;
    if (vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce araç seçin.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _fetchingServices = true;
    });

    try {
      final String? accessToken = await ServiceLocator.tokens.readAccessToken();
      final FleetEventClient client = HttpFleetEventClient();
      // Vehicle UUID is parsed from code/id. Wait, state.vehicleUuidFor(vehicle.code)
      final String? uuid = state.vehicleUuidFor(vehicle.code);
      if (uuid != null) {
        _fetchedServices = await client.fetchServices(uuid, accessToken: accessToken);
      }
    } catch (e) {
      debugPrint('Servis çekme hatası: $e');
      if (!mounted) return;
      setState(() {
        _fetchingServices = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
      return;
    } finally {
      setState(() {
        _fetchingServices = false;
      });
    }

    if (!mounted) return;

    if (_fetchedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu araç için servis bulunamadı veya bağlantı hatası oluştu.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final String? picked = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Servis seçin'),
          content: SizedBox(
            width: 300,
            height: 264, // Saat seçici ile aynı yükseklik
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: context.moduleBorderColor(accent), width: 2.5),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.builder(
                itemExtent: 44, // Saat seçici ile aynı satır yüksekliği
                itemCount: _fetchedServices.length,
                itemBuilder: (context, index) {
                  final String service = _fetchedServices[index];
                  final bool isSelected = _selectedService == service;
                  return InkWell(
                    onTap: () {
                      final vehicle = AppScope.read(context).selectedVehicle;
                      if (vehicle != null) {
                        final bool isDuplicate = _cart.asMap().entries.any((entry) {
                          if (_editingIndex == entry.key) return false;
                          return entry.value.vehicle.code == vehicle.code && entry.value.serviceType == service;
                        });

                        if (isDuplicate) {
                          showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              content: SizedBox(
                                width: 400,
                                child: Text(
                                  'Bu araç için "$service" işlemi devam eden servis kayıtları arasında bulunmaktadır. Lütfen farklı bir işlem seçiniz.',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Tamam', style: TextStyle(fontSize: 16)),
                                )
                              ],
                            ),
                          );
                          return;
                        }
                      }
                      Navigator.pop(ctx, service);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      color: isSelected ? accent : null,
                      child: Text(
                        service,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                  foregroundColor: context.isDark ? Colors.white : Colors.green),
              child: const Text('Vazgeç'),
            ),
          ],
        );
      }
    );
    if (picked != null) {
      setState(() {
        if (_selectedService != picked) {
          _startTime = null;
          _endTime = null;
        }
        _selectedService = picked;
      });
    }
  }


  void _saveToCart() {
    final AppState state = AppScope.of(context);
    final Vehicle? vehicle = state.selectedVehicle;
    
    final List<String> errors = <String>[];
    if (vehicle == null) errors.add('Lütfen işlem yapılacak aracı seçin.');
    if (_selectedService == null) errors.add('Lütfen yapılan servisi seçin.');
    if (widget.showServiceHours && _startTime == null) {
      errors.add('Başlangıç saatini seçmediniz.');
    }

    if (errors.isNotEmpty) {
      _showValidationPopup(errors);
      return;
    }

    // Sepette (düzenlenen hariç) aynı araç ve aynı servis var mı kontrolü
    final bool isDuplicate = _cart.asMap().entries.any((entry) {
      if (_editingIndex == entry.key) return false;
      return entry.value.vehicle.code == vehicle!.code && entry.value.serviceType == _selectedService;
    });

    if (isDuplicate) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            width: 400,
            child: Text(
              'Bu araç için "$_selectedService" işlemi devam eden servis kayıtları arasında bulunmaktadır. Lütfen farklı bir işlem seçiniz.',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tamam', style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      );
      return;
    }

    setState(() {
      if (_editingIndex != null && _editingIndex! < _cart.length) {
        _cart[_editingIndex!] = _ServiceCartItem(
          vehicle: vehicle!,
          images: List.from(_images),
          description: _description.text.trim(),
          serviceType: _selectedService,
          startTime: _startTime,
          endTime: _endTime,
        );
        // Düzenlenen kayıt kaydedildikten sonra form ekranda kalsın, sadece düzenleme modundan çıkalım.
        _editingIndex = null;
      } else {
        _cart.add(_ServiceCartItem(
          vehicle: vehicle!,
          images: List.from(_images),
          description: _description.text.trim(),
          serviceType: _selectedService,
          startTime: _startTime,
          endTime: _endTime,
        ));
        
        // Yeni bir kayıt sıfırdan ekleniyorsa formu sıfırla
        state.selectVehicle(null);
        _images.clear();
        _description.clear();
        _selectedService = null;
        _startTime = null;
        _endTime = null;
        _editingIndex = null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İşlem başarıyla kaydedildi!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showCart() async {
    if (_cart.isEmpty) return;
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Devam Eden Servisler',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _cart.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = _cart[index];
                    final timeStr = (item.startTime != null && item.endTime != null)
                        ? '(${_formatTime(item.startTime!)} - ${_formatTime(item.endTime!)})'
                        : '';
                    return ListTile(
                      onTap: () {
                        setState(() {
                          _editingIndex = index;
                          AppScope.read(context).selectVehicle(item.vehicle);
                          _images.clear();
                          _images.addAll(item.images);
                          _description.text = item.description;
                          _selectedService = item.serviceType;
                          _startTime = item.startTime;
                          _endTime = item.endTime;
                        });
                        Navigator.pop(ctx);
                      },
                      leading: CircleAvatar(
                        backgroundColor: accent,
                        child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text('${item.vehicle.code} - ${item.serviceType ?? ""}'),
                      subtitle: Text(timeStr),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _cart.removeAt(index);
                            if (_editingIndex == index) _editingIndex = null;
                            else if (_editingIndex != null && _editingIndex! > index) _editingIndex = _editingIndex! - 1;
                          });
                          Navigator.pop(ctx);
                          if (_cart.isNotEmpty) _showCart();
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Kapat'),
              ),
            ],
          ),
        ),
      ),
    );
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

    final List<String> errors = <String>[];
    if (vehicle == null) errors.add('Lütfen işlem yapılacak aracı seçin.');
    if (widget.showServiceHours && _selectedService == null) {
      errors.add('Lütfen yapılan servisi seçin.');
    }
    if (widget.showServiceHours && _startTime == null) {
      errors.add('Başlangıç saatini seçmediniz.');
    }
    if (widget.showServiceHours && _endTime == null) {
      errors.add('Bitiş saatini seçmediniz.');
    }

    if (errors.isNotEmpty) {
      _showValidationPopup(errors);
      return;
    }

    setState(() => _sending = true);

    final List<String> imagePaths = _images.map((XFile f) => f.path).toList();
    
    final String? startText = widget.showServiceHours && _startTime != null
        ? _formatTime(_startTime!)
        : null;
    final String? endText = widget.showServiceHours && _endTime != null
        ? _formatTime(_endTime!)
        : null;
    final String hours = startText == null && endText == null
        ? ''
        : '${startText ?? '-'} - ${endText ?? '-'}';

    final String fullDescription = _selectedService != null && _selectedService!.isNotEmpty
        ? '[$_selectedService] - ${_description.text}'
        : _description.text;

    final PublishResult result = await PublishService.instance.publishReport(
      state: state,
      reportType: widget.type.label,
      service: _selectedService,
      description: fullDescription,
      imagePaths: imagePaths,
      items: const <Map<String, Object?>>[],
      vehicleCode: vehicle!.code,
      userRegistryNo: state.user?.registryNo,
      startTime: startText,
      endTime: endText,
    );

    if (!result.success) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            '${vehicle.code} gönderilirken hata oluştu: ${result.error ?? "bilinmeyen hata"}.',
          ),
        ));
      return;
    }

    final DateTime sentAt = DateTime.now();
    state.addActivity(
      ServiceReportActivity(
        id: 'rapor-${sentAt.microsecondsSinceEpoch}',
        vehicleCode: vehicle.code,
        date: sentAt,
        reportType: widget.type.label,
        description: fullDescription,
        imagePaths: imagePaths,
        itemCount: 0,
      ),
    );
    state.addNotification(
      NotificationItem(
        title: 'Servis raporu gönderildi',
        message: '${widget.type.label} • ${imagePaths.length} görsel'
            ' • ${vehicle.code}'
            '${hours.isEmpty ? '' : ' • $hours'}',
        date: sentAt,
        kind: NotificationKind.form,
        vehicleCode: vehicle.code,
        details: <String, String>{
          'Rapor türü': widget.type.label,
          'Araç': vehicle.code,
          'Başlangıç saati': startText ?? '-',
          'Bitiş saati': endText ?? '-',
          'Gönderilen görsel': '${imagePaths.length}',
          'Açıklama': fullDescription,
          'Gönderim tarihi': formatDateTime(sentAt),
        },
      ),
    );

    if (!mounted) return;
    final String? sentServiceName = _selectedService;

    setState(() {
      _sending = false;
      if (_editingIndex != null && _editingIndex! < _cart.length) {
        _cart.removeAt(_editingIndex!);
      }
      _images.clear();
      _description.clear();
      _endTime = null;
      _startTime = null;
      _selectedService = null;
      _editingIndex = null;
      state.selectVehicle(null);
    });

    await showResultDialog(
      context,
      title: 'Gönderim Başarılı',
      subtitle: formatDateTime(sentAt),
      details: <String, String>{
        'Araç': vehicle.code,
        if (sentServiceName != null) 'Servis': sentServiceName,
        if (startText != null) 'Başlangıç': startText,
        if (endText != null) 'Bitiş': endText,
      },
    );
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
                      onSelected: (Vehicle? newVehicle) {
                        if (newVehicle != null) {
                          if (_editingIndex != null && newVehicle.code != _cart[_editingIndex!].vehicle.code) {
                            showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('İşlem Tamamlanmadı', style: TextStyle(fontSize: 22)),
                                content: const SizedBox(
                                  width: 400,
                                  child: Text('Lütfen önce yaptığınız işlemi kaydedin.', style: TextStyle(fontSize: 16)),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Tamam', style: TextStyle(fontSize: 16)),
                                  )
                                ],
                              ),
                            );
                            return;
                          }

                          // Eğer araç gerçekten değişiyorsa formu sıfırla
                          if (state.selectedVehicle?.code != newVehicle.code) {
                            setState(() {
                              _images.clear();
                              _description.clear();
                              _startTime = null;
                              _endTime = null;
                              _selectedService = null;
                              _editingIndex = null;
                            });
                          }
                        }
                        state.selectVehicle(newVehicle);
                      },
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
        // 1. Kayıt Göstergesi
        _buildActionBox(
          context,
          label: null,
          value: _cart.isEmpty ? 'Servis kaydı bulunmamaktadır' : 'Devam Eden Servisler (${_cart.length})',
          icon: Icons.assignment_outlined,
          isSet: _cart.isNotEmpty,
          width: 280,
          onTap: _showCart,
        ),
        // 2. Servis Seç
        _buildActionBox(
          context,
          label: 'Servis Seç',
          value: _fetchingServices ? 'Yükleniyor...' : (_selectedService ?? 'Servis seçin'),
          icon: _fetchingServices ? Icons.hourglass_empty : Icons.build_circle_outlined,
          isSet: _selectedService != null,
          isDisabled: _editingIndex != null || _fetchingServices,
          onTap: _pickService,
        ),
        // 3. Başlangıç Saati
        _buildActionBox(
          context,
          label: 'Başlangıç Saati',
          value: _startTime != null ? _formatTime(_startTime!) : 'Saat seçin',
          icon: Icons.schedule_outlined,
          isSet: _startTime != null,
          isDisabled: _editingIndex != null,
          onTap: () => _pickTime(isStart: true),
        ),
        // 4. Bitiş Saati
        _buildActionBox(
          context,
          label: 'Bitiş Saati',
          value: _endTime != null ? _formatTime(_endTime!) : 'Saat seçin',
          icon: Icons.schedule_outlined,
          isSet: _endTime != null,
          color: Colors.green,
          onTap: () => _pickTime(isStart: false),
        ),
        // 5. İşlemi Kaydet (Toplu işlem için sepete atar veya günceller)
        _buildActionBox(
          context,
          label: null,
          value: 'İşlemi Kaydet',
          icon: Icons.save_outlined,
          isSet: true,
          color: Colors.blue,
          onTap: _saveToCart,
        ),
      ],
    );
  }

  /// Genel buton/seçici kutu yapısı
  Widget _buildActionBox(
    BuildContext context, {
    String? label,
    required String value,
    IconData? icon,
    required VoidCallback onTap,
    bool isSet = false,
    bool isDisabled = false,
    Color? color,
    double width = 175,
  }) {
    final effectiveColor = color ?? accent;
    return SizedBox(
      width: width,
      height: 52, // Hepsini aynı yüksekliğe sabitliyoruz
      child: Opacity(
        opacity: isDisabled ? 0.45 : 1.0,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isSet
                  ? effectiveColor.withValues(alpha: 0.1)
                  : (context.isDark ? Colors.black26 : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSet ? effectiveColor : context.moduleBorderColor(effectiveColor),
                  width: 2.5),
            ),
            child: Row(
              mainAxisAlignment: (label == null && icon == null) 
                  ? MainAxisAlignment.center 
                  : MainAxisAlignment.start,
              children: <Widget>[
                if (icon != null) ...[
                  Icon(icon, size: 20, color: isSet ? effectiveColor : context.mutedColor),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: (label == null && icon == null) 
                        ? CrossAxisAlignment.center 
                        : CrossAxisAlignment.start,
                    children: <Widget>[
                      if (label != null) ...[
                        Text(label,
                            style: TextStyle(
                                fontSize: 11,
                                color: context.isDark ? Colors.white : context.mutedColor)),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.isDark
                              ? Colors.white
                              : (isSet ? null : context.mutedColor),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
        SizedBox(
          width: 260,
          child: FilledButton.icon(
            onPressed: ((widget.showServiceHours && _endTime == null) || _sending) ? null : _send,
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
            label: Text(_sending ? 'Gönderiliyor...' : 'Gönder'),
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

  void _showFullScreenImage(BuildContext context, XFile file) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: kIsWeb
                        ? Image.network(file.path, fit: BoxFit.contain)
                        : Image.file(File(file.path), fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.65),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThumb(BuildContext context, int index) {
    final XFile file = _images[index];
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GestureDetector(
            onTap: () => _showFullScreenImage(context, file),
            child: kIsWeb
                ? Image.network(file.path, fit: BoxFit.cover)
                : Image.file(File(file.path), fit: BoxFit.cover,
                    errorBuilder: (BuildContext c, Object e, StackTrace? s) {
                    return Container(
                      color: context.cardColor,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    );
                  }),
          ),
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
            child: IgnorePointer(
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
    this.minTime,
  });

  final String title;

  /// Alanda hâlihazırda seçili olan saat; yoksa liste seçimsiz açılır.
  final TimeOfDay? initial;

  final Color accent;

  /// Eğer verilirse, bu saat/dakikadan önceki değerler buğulu/devre dışı bırakılır.
  final TimeOfDay? minTime;

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
              isItemDisabled: (int h) {
                if (widget.minTime == null) return false;
                return h < widget.minTime!.hour;
              },
              onSelected: (int v) {
                setState(() {
                  _hour = v;
                  // Eğer seçilen saat minTime saatiyse ve mevcut dakika minTime dakikasından küçük/eşitse dakikayı sıfırla
                  if (widget.minTime != null &&
                      _hour == widget.minTime!.hour &&
                      _minute != null &&
                      _minute! <= widget.minTime!.minute) {
                    _minute = null;
                  }
                });
              },
            ),
            const SizedBox(width: 16),
            _buildColumn(
              context,
              label: 'Dakika',
              count: 60,
              selected: _minute,
              controller: _minuteScroll,
              isItemDisabled: (int m) {
                if (widget.minTime == null) return false;
                if (_hour == null) return true;
                if (_hour! < widget.minTime!.hour) return true;
                if (_hour! == widget.minTime!.hour) {
                  return m <= widget.minTime!.minute;
                }
                return false;
              },
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
          // İkisi de seçilmeden ve geçerli olmadan saat oluşturulamaz.
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
    bool Function(int item)? isItemDisabled,
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
            border: Border.all(
                color: context.moduleBorderColor(widget.accent), width: 2.5),
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
                final bool isDisabled = isItemDisabled?.call(i) ?? false;

                if (isDisabled) {
                  return Container(
                    alignment: Alignment.center,
                    color: context.isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.grey.shade100,
                    child: Text(
                      i.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: context.mutedColor.withValues(alpha: 0.3),
                      ),
                    ),
                  );
                }

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
