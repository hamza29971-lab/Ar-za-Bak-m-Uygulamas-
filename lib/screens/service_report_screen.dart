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
import '../widgets/nimo_table.dart';
import '../widgets/vehicle_selector.dart';

/// Gönderilebilecek rapor türleri.
enum ReportType {
  /// Seçilen aracın lastik kayıtları rapora eklenir.
  tireChange('Lastik Değişim Raporu', Icons.trip_origin),

  /// Seçilen aracın yağ takviyesi kayıtları rapora eklenir.
  oilRefill('Yağ Takviye Raporu', Icons.water_drop_outlined),

  /// Araç kaydı okunmaz; yalnızca görsel ve açıklama gönderilir.
  fault('Arıza Raporu', Icons.report_gmailerrorred_outlined);

  const ReportType(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Rapor, araç kayıtlarından veri çekiyor mu?
  bool get usesVehicleData => this != ReportType.fault;
}

/// "Servis Raporu" ekranı: rapor türü + araç kayıtları + görsel(ler) + açıklama.
class ServiceReportScreen extends StatefulWidget {
  const ServiceReportScreen({super.key});

  static const Color accent = AppColors.form;

  @override
  State<ServiceReportScreen> createState() => _ServiceReportScreenState();
}

class _ServiceReportScreenState extends State<ServiceReportScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _description = TextEditingController();
  final List<XFile> _images = <XFile>[];
  ReportType _type = ReportType.tireChange;
  bool _sending = false;

  /// Araç tablosu görünürken görsel/açıklama kartlarının yüksekliği.
  static const double _cardsHeight = 380;

  Color get accent => ServiceReportScreen.accent;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ rapor verisi

  /// Rapora eklenecek lastik kayıtları.
  List<TireRecord> _tireRows(AppState state, Vehicle? vehicle) =>
      vehicle == null || _type != ReportType.tireChange
          ? <TireRecord>[]
          : state.tiresOf(vehicle);

  /// Rapora eklenecek yağ takviyesi kayıtları ("Manuel Yağlamalar" hariç).
  List<OilRecord> _oilRows(AppState state, Vehicle? vehicle) =>
      vehicle == null || _type != ReportType.oilRefill
          ? <OilRecord>[]
          : state
              .oilsOf(vehicle)
              .where((OilRecord r) => r.category == OilCategory.refill)
              .toList();

  /// Rapor gövdesine (MQTT yüküne) eklenecek satırlar.
  List<Map<String, Object?>> _payloadItems(AppState state, Vehicle? vehicle) {
    return <Map<String, Object?>>[
      for (final TireRecord r in _tireRows(state, vehicle))
        <String, Object?>{
          'tireId': r.tireId,
          'position': r.position,
          'serialNo': r.serialNo,
          'lastChangeDate': r.lastChangeDate.toIso8601String(),
          'lastCheckDate': r.lastCheckDate.toIso8601String(),
        },
      for (final OilRecord r in _oilRows(state, vehicle))
        <String, Object?>{
          'areaId': r.areaId,
          'oilType': r.oilType,
          'amount': r.amount,
          'lastOilDate': r.lastOilDate.toIso8601String(),
          'lastCheckDate': r.lastCheckDate.toIso8601String(),
        },
    ];
  }

  // ---------------------------------------------------------------- görseller

  Future<void> _pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return;
      setState(() => _images.addAll(picked));
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel seçilemedi: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? shot = await _picker.pickImage(source: ImageSource.camera);
      if (shot == null) return;
      setState(() => _images.add(shot));
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kamera kullanılamadı: $e')),
      );
    }
  }

  // ------------------------------------------------------------------ gönder

  Future<void> _send() async {
    final AppState state = AppScope.read(context);
    final Vehicle? vehicle = state.selectedVehicle;

    if (_type.usesVehicleData && vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapor için önce araç seçin.')),
      );
      return;
    }
    if (_images.isEmpty && _description.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir görsel ekleyin veya açıklama yazın.')),
      );
      return;
    }

    final List<Map<String, Object?>> items = _payloadItems(state, vehicle);
    final List<String> imagePaths = _images.map((XFile f) => f.path).toList();

    setState(() => _sending = true);
    final PublishResult result = await PublishService.instance.publishReport(
      reportType: _type.label,
      description: _description.text.trim(),
      imagePaths: imagePaths,
      items: items,
      vehicleCode: vehicle?.code,
      userRegistryNo: state.user?.registryNo,
    );
    if (!mounted) return;
    setState(() => _sending = false);

    final DateTime sentAt = DateTime.now();
    state.addActivity(
      ServiceReportActivity(
        id: 'rapor-${sentAt.microsecondsSinceEpoch}',
        vehicleCode: vehicle?.code ?? '',
        date: sentAt,
        reportType: _type.label,
        description: _description.text.trim(),
        imagePaths: imagePaths,
        itemCount: items.length,
      ),
    );
    state.addNotification(
      NotificationItem(
        title: 'Servis raporu gönderildi',
        message: '${_type.label} • ${imagePaths.length} görsel'
            '${vehicle != null ? ' • ${vehicle.code}' : ''}',
        date: sentAt,
        kind: NotificationKind.form,
      ),
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.brand, size: 42),
        title: const Text('Rapor gönderildi'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InfoLine(label: 'Rapor türü', value: _type.label, labelWidth: 110),
              InfoLine(label: 'Araç', value: vehicle?.code ?? '-', labelWidth: 110),
              if (_type.usesVehicleData)
                InfoLine(
                  label: 'Kayıt',
                  value: '${items.length} satır',
                  labelWidth: 110,
                ),
              InfoLine(
                label: 'Görsel',
                value: '${imagePaths.length} adet',
                labelWidth: 110,
              ),
              InfoLine(label: 'MQTT konusu', value: result.topic, labelWidth: 110),
            ],
          ),
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    setState(() {
      _images.clear();
      _description.clear();
    });
  }

  // ------------------------------------------------------------------ arayüz

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final Vehicle? vehicle = state.selectedVehicle;

    return NimoPage(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const PageHeading(
              title: 'Servis Raporu',
              subtitle: 'Rapor türünü ve aracı seçin, görsel ve açıklama ile gönderin',
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                // Liste alanın üstünü kapatmasın diye DropdownMenu kullanılır;
                // menü her zaman alanın altına açılır.
                DropdownMenu<ReportType>(
                  width: 320,
                  menuHeight: 320,
                  initialSelection: _type,
                  requestFocusOnTap: false,
                  label: const Text('Rapor türü'),
                  leadingIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: Icon(_type.icon, size: 20, color: accent),
                  ),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  dropdownMenuEntries: <DropdownMenuEntry<ReportType>>[
                    for (final ReportType t in ReportType.values)
                      DropdownMenuEntry<ReportType>(
                        value: t,
                        label: t.label,
                        leadingIcon: Icon(t.icon, size: 18, color: accent),
                      ),
                  ],
                  onSelected: (ReportType? v) => setState(() => _type = v ?? _type),
                ),
                const SizedBox(width: 16),
                // Araç listeden seçilir; seçim diğer ekranlarla ortaktır.
                VehicleSelector(
                  selected: vehicle,
                  accentColor: accent,
                  width: 360,
                  onSelected: state.selectVehicle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              // Araç kayıtları tüm satırlarıyla listelenir; sığmadığında tablo
              // kendi içinde değil, sayfa kaydırılır.
              child: _type.usesVehicleData
                  ? SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildDataSection(context, state, vehicle),
                          const SizedBox(height: 20),
                          SizedBox(height: _cardsHeight, child: _buildCards(context)),
                        ],
                      ),
                    )
                  : _buildCards(context),
            ),
            // Gönderim alanı, rapor araç kaydı kullanıyorsa yalnızca araç
            // seçildikten sonra görünür.
            if (!_type.usesVehicleData || vehicle != null) ...<Widget>[
              const SizedBox(height: 20),
              _buildActions(context),
            ],
          ],
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

  /// Rapora eklenecek araç kayıtları (lastik / yağ takviyesi).
  Widget _buildDataSection(BuildContext context, AppState state, Vehicle? vehicle) {
    final bool tire = _type == ReportType.tireChange;
    final int rowCount =
        tire ? _tireRows(state, vehicle).length : _oilRows(state, vehicle).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(_type.icon, size: 18, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tire
                    ? 'Rapora Eklenecek Lastik Kayıtları'
                    : 'Rapora Eklenecek Yağ Takviyesi Kayıtları',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              vehicle == null ? 'Araç seçilmedi' : '$rowCount kayıt',
              style: TextStyle(fontSize: 13, color: context.mutedColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (tire)
          _buildTireTable(context, state, vehicle)
        else
          _buildOilTable(context, state, vehicle),
      ],
    );
  }

  Widget _buildTireTable(BuildContext context, AppState state, Vehicle? vehicle) {
    final List<TireRecord> rows = _tireRows(state, vehicle);

    return NimoTable(
      accent: accent,
      shrinkWrap: true,
      columns: const <NimoColumn>[
        NimoColumn('Lastik ID', flex: 26),
        NimoColumn('Seri No', flex: 22),
        NimoColumn('Son Değiştirme Tarihi', flex: 26),
        NimoColumn('Son Kontrol Tarihi', flex: 26),
      ],
      rowCount: rows.length,
      empty: _emptyState(vehicle, 'lastik'),
      cellsBuilder: (BuildContext context, int index) {
        final TireRecord r = rows[index];

        return <Widget>[
          CellText(r.tireId, subtitle: r.position, bold: true),
          CellText(r.serialNo),
          CellText(
            formatDate(r.lastChangeDate),
            subtitle: '${daysSince(r.lastChangeDate)} gün önce',
          ),
          CellText(
            formatDate(r.lastCheckDate),
            subtitle: '${daysSince(r.lastCheckDate)} gün önce',
          ),
        ];
      },
    );
  }

  Widget _buildOilTable(BuildContext context, AppState state, Vehicle? vehicle) {
    final List<OilRecord> rows = _oilRows(state, vehicle);

    return NimoTable(
      accent: accent,
      shrinkWrap: true,
      columns: const <NimoColumn>[
        NimoColumn('Yağ Takviyesi Türü', flex: 34),
        NimoColumn('Son Yağ Takviyesi', flex: 33),
        NimoColumn('Son Kontrol Tarihi', flex: 33),
      ],
      rowCount: rows.length,
      empty: _emptyState(vehicle, 'yağ takviyesi'),
      cellsBuilder: (BuildContext context, int index) {
        final OilRecord r = rows[index];

        return <Widget>[
          CellText(r.oilType, subtitle: r.areaId, bold: true),
          CellText(
            formatDate(r.lastOilDate),
            subtitle: '${daysSince(r.lastOilDate)} gün önce',
          ),
          CellText(
            formatDate(r.lastCheckDate),
            subtitle: '${daysSince(r.lastCheckDate)} gün önce',
          ),
        ];
      },
    );
  }

  Widget _emptyState(Vehicle? vehicle, String what) {
    return EmptyState(
      icon: _type.icon,
      title: vehicle == null ? 'Araç seçilmedi' : 'Kayıt bulunamadı',
      message: vehicle == null
          ? 'Rapora eklenecek kayıtları görmek için yukarıdaki "Araç Seç" alanından bir araç seçin.'
          : 'Bu araç için $what kaydı bulunmuyor.',
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        if (_images.isNotEmpty || _description.text.isNotEmpty)
          TextButton.icon(
            onPressed: _sending
                ? null
                : () => setState(() {
                      _images.clear();
                      _description.clear();
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
      expandChild: true,
      trailing: Text('${_images.length} görsel',
          style: TextStyle(fontSize: 13, color: context.mutedColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
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
                  Text('Birden fazla görsel seçebilirsiniz.',
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
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: child,
    );
  }
}
