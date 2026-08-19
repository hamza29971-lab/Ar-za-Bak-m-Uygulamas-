import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/common.dart';
import '../widgets/nimo_page.dart';
import '../widgets/nimo_table.dart';

import '../widgets/vehicle_selector.dart';

/// "Yağ Takviyesi" ekranı.
/// Kayıtlar "Yağ Takviyeleri" ve "Manuel Yağlamalar" olarak iki grupta listelenir.
class OilScreen extends StatefulWidget {
  const OilScreen({super.key});

  static const Color accent = AppColors.oil;

  @override
  State<OilScreen> createState() => _OilScreenState();
}

class _OilScreenState extends State<OilScreen> {
  OilCategory _category = OilCategory.refill;

  Color get accent => OilScreen.accent;

  /// Seçili gruba göre tarih sütununun başlığı.
  String get _dateColumnLabel =>
      _category == OilCategory.refill ? 'Son Yağ Takviyesi' : 'Son Manuel Yağlama';

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final Vehicle? vehicle = state.selectedVehicle;
    final List<OilRecord> records = vehicle == null
        ? <OilRecord>[]
        : state
            .oilsOf(vehicle)
            .where((OilRecord r) => r.category == _category)
            .toList();

    return NimoPage(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const PageHeading(
                    title: 'Yağ Takviyesi',
                    subtitle: 'Araç yağ takviyesi ve manuel yağlama kayıtları',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      VehicleSelector(
                        selected: vehicle,
                        accentColor: accent,
                        onSelected: state.selectVehicle,
                      ),
                      const SizedBox(width: 16),
                      if (vehicle != null)
                        _OilSummary(records: records, category: _category),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      // Dar ekranlarda sekmeler yatay kayar, buton sağda kalır.
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _buildCategoryTabs(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Satır seçmeden, tür + miktar seçilerek takviye yapılır.
                      _NewRefillButton(
                        label: 'Takviye Yap',
                        accent: accent,
                        onPressed: vehicle == null || records.isEmpty
                            ? null
                            : () => _newRefillDialog(context, state, vehicle, records),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildTable(context, state, vehicle, records)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 50,
              child: SizedBox.expand(
                child: _VehicleSidePhoto(vehicle: vehicle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Yağ Takviyeleri" / "Manuel Yağlamalar" grup seçimi.
  Widget _buildCategoryTabs(BuildContext context) {
    return SegmentedTabs<OilCategory>(
      accent: accent,
      selected: _category,
      onChanged: (OilCategory c) => setState(() => _category = c),
      items: <SegmentedTabItem<OilCategory>>[
        for (final OilCategory c in OilCategory.values)
          SegmentedTabItem<OilCategory>(
            value: c,
            label: c.pluralLabel,
            icon: c == OilCategory.refill
                ? Icons.water_drop_outlined
                : Icons.handyman_outlined,
          ),
      ],
    );
  }

  Widget _buildTable(
    BuildContext context,
    AppState state,
    Vehicle? vehicle,
    List<OilRecord> records,
  ) {
    return NimoTable(
      accent: accent,
      // "İşlem" başlığı butonların üstüne gelecek şekilde sağa kaydırılır.
      columns: <NimoColumn>[
        NimoColumn(_category.columnLabel, flex: 24),
        NimoColumn(_dateColumnLabel, flex: 22),
        const NimoColumn('Son Kontrol Tarihi', flex: 22),
        const NimoColumn('İşlem', flex: 32, headerInset: 92),
      ],
      rowCount: records.length,
      empty: EmptyState(
        icon: Icons.water_drop_outlined,
        title: vehicle == null ? 'Araç seçilmedi' : 'Kayıt bulunamadı',
        message: vehicle == null
            ? 'Yağ takviyesi kayıtlarını görmek için yukarıdaki "Araç Seç" alanından bir araç seçin.'
            : 'Bu araç için ${_category.pluralLabel.toLowerCase()} kaydı bulunmuyor.',
      ),
      cellsBuilder: (BuildContext context, int index) {
        final OilRecord r = records[index];

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              RowActionButton(
                label: 'Takviye Yap',
                icon: Icons.local_gas_station_outlined,
                color: accent,
                onPressed: () => _refillDialog(context, state, vehicle!, r),
              ),
              RowActionButton(
                label: 'Kontrol Et',
                icon: Icons.fact_check_outlined,
                color: AppColors.form,
                filled: false,
                onPressed: () {
                  state.checkOil(vehicle!, r);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Kontroller Tamamlandı')),
                    );
                },
              ),
            ],
          ),
        ];
      },
    );
  }

  /// Satırdaki "Takviye Yap": miktarı sorar. Tür satıra sabit olduğu için seçilemez.
  Future<void> _refillDialog(
    BuildContext context,
    AppState state,
    Vehicle vehicle,
    OilRecord record,
  ) async {
    final double? value = await showDialog<double>(
      context: context,
      builder: (BuildContext context) =>
          _OilRefillDialog(vehicle: vehicle, record: record),
    );

    if (value == null || !context.mounted) return;
    _commitRefill(context, state, vehicle, record, value);
  }

  /// Sekmelerin yanındaki "Takviye Yap": önce tür, sonra miktar seçilir.
  /// Seçenekler o an açık olan grubun (takviye / manuel yağlama) kayıtlarıdır.
  Future<void> _newRefillDialog(
    BuildContext context,
    AppState state,
    Vehicle vehicle,
    List<OilRecord> records,
  ) async {
    final _RefillRequest? request = await showDialog<_RefillRequest>(
      context: context,
      builder: (BuildContext context) => _OilTypePickerDialog(
        vehicle: vehicle,
        records: records,
        category: _category,
      ),
    );

    if (request == null || !context.mounted) return;
    _commitRefill(context, state, vehicle, request.record, request.amount);
  }

  /// Takviyeyi kaydeder ve kullanıcıya bilgi verir.
  void _commitRefill(
    BuildContext context,
    AppState state,
    Vehicle vehicle,
    OilRecord record,
    double amount,
  ) {
    state.refillOil(vehicle, record, amount);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content:
            Text('${record.oilType} için ${amount.toStringAsFixed(1)} L kaydedildi.'),
      ));
  }
}

/// Sekmelerin yanındaki ana "Takviye Yap" butonu.
/// Tablodaki satır butonlarından ayrışsın diye biraz daha büyük, yuvarlak hatlı
/// ve ikonu çerçeve içinde.
class _NewRefillButton extends StatelessWidget {
  const _NewRefillButton({
    required this.label,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color base = enabled ? accent : context.mutedColor.withValues(alpha: 0.35);

    return Material(
      color: base,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tür seçilerek yapılan takviyenin sonucu.
class _RefillRequest {
  const _RefillRequest(this.record, this.amount);

  final OilRecord record;
  final double amount;
}

/// Tür + miktar seçilen "Takviye Yap" penceresi.
/// Kaydedilirse seçilen kayıt ve litre değeri ile kapanır.
class _OilTypePickerDialog extends StatefulWidget {
  const _OilTypePickerDialog({
    required this.vehicle,
    required this.records,
    required this.category,
  });

  final Vehicle vehicle;

  /// Seçilebilecek kayıtlar (açık olan grubun tümü).
  final List<OilRecord> records;
  final OilCategory category;

  @override
  State<_OilTypePickerDialog> createState() => _OilTypePickerDialogState();
}

class _OilTypePickerDialogState extends State<_OilTypePickerDialog> {
  late OilRecord _record = widget.records.first;
  late final TextEditingController _amount =
      TextEditingController(text: _record.amount.toStringAsFixed(1));

  bool get _manual => widget.category == OilCategory.manual;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// Tür değişince miktar, o türün son kullanılan değerine çekilir.
  void _selectRecord(OilRecord? record) {
    if (record == null || record == _record) return;
    setState(() {
      _record = record;
      _amount.text = record.amount.toStringAsFixed(1);
    });
  }

  void _save() {
    final double value =
        double.tryParse(_amount.text.replaceAll(',', '.')) ?? _record.amount;
    if (value <= 0) return;
    Navigator.of(context).pop(_RefillRequest(_record, value));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_manual ? 'Manuel Yağlama' : 'Yağ Takviyesi'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.vehicle.code,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            Text(widget.category.columnLabel, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<OilRecord>(
              initialValue: _record,
              isExpanded: true,
              items: <DropdownMenuItem<OilRecord>>[
                for (final OilRecord r in widget.records)
                  DropdownMenuItem<OilRecord>(value: r, child: Text(r.label)),
              ],
              onChanged: _selectRecord,
            ),
            const SizedBox(height: 16),
            Text(_manual ? 'Kullanılan yağ miktarı (Litre)' : 'Takviye miktarı (Litre)',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(suffixText: 'L'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            InfoLine(
              label: _manual ? 'Yağlama tarihi' : 'Takviye tarihi',
              value: formatDateTime(DateTime.now()),
              labelWidth: 120,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(backgroundColor: OilScreen.accent),
          child: Text(_manual ? 'Yağlamayı Kaydet' : 'Takviyeyi Kaydet'),
        ),
      ],
    );
  }
}

/// "Takviye Yap" penceresi: yalnızca miktar girilir, tür sabittir.
/// Kaydedilirse girilen litre değeri ile kapanır.
class _OilRefillDialog extends StatefulWidget {
  const _OilRefillDialog({required this.vehicle, required this.record});

  final Vehicle vehicle;
  final OilRecord record;

  @override
  State<_OilRefillDialog> createState() => _OilRefillDialogState();
}

class _OilRefillDialogState extends State<_OilRefillDialog> {
  late final TextEditingController _amount =
      TextEditingController(text: widget.record.amount.toStringAsFixed(1));

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final double value =
        double.tryParse(_amount.text.replaceAll(',', '.')) ?? widget.record.amount;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final OilRecord record = widget.record;
    final bool manual = record.category == OilCategory.manual;

    return AlertDialog(
      title: Text(manual ? 'Manuel Yağlama' : 'Yağ Takviyesi'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('${widget.vehicle.code} • ${record.label}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            Text(record.category.columnLabel, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            // Tür satıra sabittir; kullanıcı yalnızca bastığı satıra işlem yapar.
            _ReadOnlyField(value: record.oilType),
            const SizedBox(height: 16),
            Text(manual ? 'Kullanılan yağ miktarı (Litre)' : 'Takviye miktarı (Litre)',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(suffixText: 'L'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            InfoLine(
              label: manual ? 'Yağlama tarihi' : 'Takviye tarihi',
              value: formatDateTime(DateTime.now()),
              labelWidth: 120,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(backgroundColor: OilScreen.accent),
          child: Text(manual ? 'Yağlamayı Kaydet' : 'Takviyeyi Kaydet'),
        ),
      ],
    );
  }
}

/// Değiştirilemeyen (sabit) alan görünümü.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.lock_outline, size: 18, color: context.mutedColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _OilSummary extends StatelessWidget {
  const _OilSummary({required this.records, required this.category});

  final List<OilRecord> records;
  final OilCategory category;

  @override
  Widget build(BuildContext context) {
    final String unit = category == OilCategory.refill ? 'alan' : 'nokta';

    return Expanded(
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: <Widget>[
          InfoChip(
            icon: Icons.water_drop_outlined,
            label: '${records.length} $unit',
            color: AppColors.oil,
          ),
        ],
      ),
    );
  }
}

class _VehicleSidePhoto extends StatelessWidget {
  const _VehicleSidePhoto({required this.vehicle});

  final Vehicle? vehicle;

  String _imagePath() {
    if (vehicle == null) return '';
    final code = vehicle!.code.toLowerCase();
    
    if (code.startsWith('euclid')) {
      return 'assets/images/euclid_truck.png';
    }
    if (code.startsWith('liugong')) {
      // 33-39 loader
      final num = int.tryParse(code.replaceFirst('liugong-', '')) ?? 0;
      if (num >= 33 && num <= 39) return 'assets/images/loader.png';
      return 'assets/images/green_truck.png';
    }
    if (code.startsWith('xcmg')) {
      return 'assets/images/xcmg_truck.png';
    }
    // Fallback
    if (vehicle!.tireCount <= 4) return 'assets/images/loader.png';
    return 'assets/images/euclid_truck.png';
  }

  @override
  Widget build(BuildContext context) {
    if (vehicle == null) {
      return const Center(
        child: Text(
          'Fotoğrafı görmek için bir araç seçin',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: Image.asset(
            _imagePath(),
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
