import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/fleet.dart';
import '../models/models.dart';
import '../services/publish_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/common.dart';
import '../widgets/nimo_page.dart';
import '../widgets/nimo_table.dart';
import '../widgets/vehicle_photo.dart';
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

  /// "Gönder" sürerken buton kilitlenir.
  bool _sending = false;

  Color get accent => OilScreen.accent;

  /// Seçili gruba göre tarih sütununun başlığı.
  String get _dateColumnLabel =>
      _category == OilCategory.refill ? 'Son Yağ Takviyesi' : 'Son Manuel Yağlama';

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final Vehicle? vehicle = state.selectedVehicle;
    final int pendingCount = state.pendingCount(PendingKind.oil);
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
              flex: 55,
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
                      if (vehicle != null) _OilSummary(records: records),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Dar ekranlarda buton grubu sekmelerin altına iner.
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      // Sekmeler sığmazsa kendi içinde yatay kayar.
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildCategoryTabs(context),
                      ),
                      // Takviye yalnızca buradan yapılır; tabloda satır başına
                      // "Takviye Yap" butonu yoktur.
                      PrimaryActionButton(
                        label: _category == OilCategory.refill
                            ? 'Takviye Yap'
                            : 'Yağlama Yap',
                        accent: accent,
                        onPressed: vehicle == null || records.isEmpty
                            ? null
                            : () =>
                                _newRefillDialog(context, state, vehicle, records),
                      ),
                      PrimaryActionButton(
                        label: 'Tümünü Kontrol Et',
                        icon: Icons.fact_check_outlined,
                        accent: AppColors.form,
                        filled: false,
                        compact: true,
                        onPressed: vehicle == null || records.isEmpty
                            ? null
                            : () => _checkAll(context, state, vehicle, records),
                      ),
                      PrimaryActionButton(
                        label: 'Gönder',
                        icon: Icons.send_rounded,
                        accent: AppColors.form,
                        badge: pendingCount,
                        compact: true,
                        onPressed: pendingCount == 0 || _sending
                            ? null
                            : () => _sendPending(context, state, vehicle),
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
              flex: 45,
              child: SizedBox.expand(child: VehiclePhoto(vehicle: vehicle)),
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
      // "İşlem" sütununda tek buton kaldığı için dar; başlık butonun soluyla
      // aynı hizada durur.
      columns: <NimoColumn>[
        NimoColumn(_category.columnLabel, flex: 30),
        NimoColumn(_dateColumnLabel, flex: 25),
        const NimoColumn('Son Kontrol Tarihi', flex: 25),
        const NimoColumn('İşlem', flex: 20),
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
          // Takviye yalnızca tablonun üstündeki butondan yapılır; satırda
          // sadece kontrol kalır.
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
        ];
      },
    );
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
    _commitRefill(context, state, vehicle, request.record, request.amount,
        request.product);
  }

  /// "Tümünü Kontrol Et": listelenen alanların tamamını kontrol edilmiş olarak
  /// işaretler. Çok kaydı birden değiştirdiği için önce onay alınır.
  Future<void> _checkAll(
    BuildContext context,
    AppState state,
    Vehicle vehicle,
    List<OilRecord> records,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Tümünü Kontrol Et'),
        content: Text(
          '${vehicle.code} aracının listelenen ${records.length} alanı '
          'kontrol edilmiş olarak işaretlenecek. Onaylıyor musunuz?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.form),
            icon: const Icon(Icons.fact_check_outlined, size: 18),
            label: const Text('Kontrol Et'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    for (final OilRecord r in records) {
      state.checkOil(vehicle, r);
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${records.length} alan kontrol edildi.')),
      );
  }

  /// "Gönder": bu ekranda yapılıp bekleyen işlemleri tek mesajda yollar.
  Future<void> _sendPending(
    BuildContext context,
    AppState state,
    Vehicle? vehicle,
  ) async {
    final List<PendingOperation> pending = state.pendingOf(PendingKind.oil);
    if (pending.isEmpty) return;

    setState(() => _sending = true);
    final PublishResult result = await PublishService.instance.publishOperations(
      topic: PendingKind.oil.topic,
      group: PendingKind.oil.label,
      operations: <Map<String, Object?>>[
        for (final PendingOperation p in pending)
          <String, Object?>{
            ...p.payload,
            'vehicle': p.vehicleCode,
            'date': p.date.toIso8601String(),
          },
      ],
      vehicleCode: vehicle?.code,
      userRegistryNo: state.user?.registryNo,
    );
    if (!context.mounted) return;
    setState(() => _sending = false);

    if (!result.success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Gönderilemedi: ${result.error ?? 'bilinmeyen hata'}'),
        ));
      return;
    }

    final int count = pending.length;
    state.clearPending(PendingKind.oil);
    state.addNotification(
      NotificationItem(
        title: 'Yağ işlemleri gönderildi',
        message: '$count işlem${vehicle != null ? ' • ${vehicle.code}' : ''}',
        date: DateTime.now(),
        kind: NotificationKind.oil,
      ),
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.brand, size: 42),
        title: const Text('İşlemler gönderildi'),
        content: SizedBox(
          width: 460,
          // Uzun listede pencere taşmasın diye içerik kaydırılır.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('$count işlem gönderildi:',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                for (final PendingOperation p in pending)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('• ${p.vehicleCode} — ${p.label}',
                        style: const TextStyle(fontSize: 13)),
                  ),
                const SizedBox(height: 12),
                InfoLine(
                  label: 'MQTT konusu',
                  value: result.topic,
                  labelWidth: 110,
                ),
              ],
            ),
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
  }

  /// Takviyeyi kaydeder ve kullanıcıya bilgi verir.
  void _commitRefill(
    BuildContext context,
    AppState state,
    Vehicle vehicle,
    OilRecord record,
    double amount,
    String product,
  ) {
    state.refillOil(vehicle, record, amount, product: product);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${record.oilType} için ${amount.toStringAsFixed(1)} L'
            ' kaydedildi ($product).'),
      ));
  }
}

/// Tür seçilerek yapılan takviyenin sonucu.
class _RefillRequest {
  const _RefillRequest(this.record, this.amount, this.product);

  final OilRecord record;
  final double amount;

  /// Kullanılan yağ / gres ürünü (bkz. [Fleet.oilProducts]).
  final String product;
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
  /// Tür seçilene kadar `null`; ürün listesi buna bağlı olarak açılır.
  OilRecord? _record;
  String? _product;
  final TextEditingController _amount = TextEditingController();

  /// Eksik alan uyarısı yalnızca kaydetmeye çalışıldıktan sonra gösterilir.
  bool _showErrors = false;

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
    final OilRecord? record = _record;
    final String? product = _product;
    final double value =
        double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
    if (record == null || product == null || value <= 0) {
      setState(() => _showErrors = true);
      return;
    }
    Navigator.of(context).pop(_RefillRequest(record, value, product));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_manual ? 'Manuel Yağlama' : 'Yağ Takviyesi'),
      content: SizedBox(
        width: 460,
        // Alan sayısı arttı; küçük tablette pencere taşmasın diye kaydırılır.
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.vehicle.code,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            Text(widget.category.columnLabel, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            // Liste alanın üstünü kapatmasın diye DropdownMenu kullanılır;
            // menü her zaman alanın altına açılır.
            DropdownMenu<OilRecord>(
              initialSelection: _record,
              requestFocusOnTap: false,
              menuHeight: 320,
              expandedInsets: EdgeInsets.zero,
              hintText: _manual
                  ? 'Manuel yağlama türünü seçin'
                  : 'Yağ takviyesi türünü seçin',
              errorText: _showErrors && _record == null
                  ? 'Önce takviye türünü seçin.'
                  : null,
              dropdownMenuEntries: <DropdownMenuEntry<OilRecord>>[
                for (final OilRecord r in widget.records)
                  DropdownMenuEntry<OilRecord>(value: r, label: r.label),
              ],
              onSelected: _selectRecord,
            ),
            const SizedBox(height: 16),
            const Text('Yağ Seçin', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            // Kullanılan ürün, ancak tür seçildikten sonra seçilebilir.
            DropdownMenu<String>(
              key: const ValueKey<String>('oil-product'),
              enabled: _record != null,
              initialSelection: _product,
              requestFocusOnTap: false,
              menuHeight: 320,
              expandedInsets: EdgeInsets.zero,
              hintText: _record == null
                  ? 'Önce takviye türünü seçin'
                  : 'Kullanılan yağı seçin',
              errorText: _showErrors && _record != null && _product == null
                  ? 'Kullanılan yağı seçin.'
                  : null,
              dropdownMenuEntries: <DropdownMenuEntry<String>>[
                for (final String p in Fleet.oilProducts)
                  DropdownMenuEntry<String>(value: p, label: p),
              ],
              onSelected: (String? p) => setState(() => _product = p),
            ),
            const SizedBox(height: 16),
            Text(_manual ? 'Kullanılan yağ miktarı (Litre)' : 'Takviye miktarı (Litre)',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                suffixText: 'L',
                errorText: _showErrors &&
                        (double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0) <= 0
                    ? 'Miktar girin.'
                    : null,
              ),
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

class _OilSummary extends StatelessWidget {
  const _OilSummary({required this.records});

  final List<OilRecord> records;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: <Widget>[
          // Hem yağ takviyeleri hem manuel yağlamalar "alan" olarak sayılır.
          InfoChip(
            icon: Icons.water_drop_outlined,
            label: '${records.length} alan',
            color: AppColors.oil,
          ),
        ],
      ),
    );
  }
}
