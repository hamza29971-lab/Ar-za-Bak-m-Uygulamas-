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
import '../widgets/pending_send_dialog.dart';
import '../widgets/result_dialog.dart';
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

  /// Satırdaki birincil butonun etiketi.
  String get _actionLabel =>
      _category == OilCategory.refill ? 'Takviye Yap' : 'Yağlama Yap';

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
            // Tablo, sayfanın yaklaşık üçte ikisini kaplar; araç görseline
            // kalan alan yeter.
            Expanded(
              flex: 62,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const PageHeading(
                    title: 'Yağ Takviyesi',
                    subtitle: 'Araç yağ takviyesi ve manuel yağlama kayıtları',
                    titleSize: 32,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: VehicleSelector(
                          selected: vehicle,
                          accentColor: accent,
                          onSelected: state.selectVehicle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Takviye artık satır bazında yapılır; buradaki tek
                      // işlem bekleyenleri göndermektir.
                      PrimaryActionButton(
                        label: 'Gönder',
                        icon: Icons.send_rounded,
                        accent: accent,
                        badge: pendingCount,
                        compact: true,
                        onPressed: pendingCount == 0 || _sending
                            ? null
                            : () => _sendPending(context, state, vehicle),
                      ),
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildTable(context, state, vehicle, records)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 38,
              child: SizedBox.expand(
                  child: vehicle == null 
                    ? Center(
                        child: Text(
                          'Fotoğrafı görmek için bir araç seçin',
                          style: TextStyle(color: context.mutedColor),
                        ),
                      ) 
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _VehicleDisplay(
                          key: ValueKey(vehicle.code),
                          vehicle: vehicle,
                        ),
                      )
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
      // "İşlem" sütununda iki buton var; dar tablette alt alta sarılırlar.
      columns: <NimoColumn>[
        NimoColumn(_category.columnLabel, flex: 24),
        NimoColumn(_dateColumnLabel, flex: 19),
        const NimoColumn('Son Kontrol Tarihi', flex: 19),
        const NimoColumn('İşlem', flex: 38),
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
        // Bu satır için gönderilmeyi bekleyen takviye varsa, kullanıcı onu
        // "Gönder"e basmadan önce düzeltebilir.
        final PendingOperation? pending =
            vehicle == null ? null : state.pendingRefillFor(vehicle, r);

        return <Widget>[
          CellText(r.oilType, subtitle: r.areaId, bold: true),
          CellText(
            r.lastOilDate != null ? formatDate(r.lastOilDate!) : '-',
            subtitle: pending != null
                ? 'Bekliyor • ${r.amount.toStringAsFixed(1)} L'
                : r.lastOilDate != null
                    ? '${daysSince(r.lastOilDate!)} gün önce'
                    : 'Henüz işlem yok',
            color: pending != null ? accent : null,
          ),
          CellText(
            r.lastCheckDate != null ? formatDate(r.lastCheckDate!) : '-',
            subtitle: r.lastCheckDate != null ? '${daysSince(r.lastCheckDate!)} gün önce' : 'Henüz kontrol yok',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              // Tür bu satırdan belli olduğu için pencerede tekrar sorulmaz.
              RowActionButton(
                label: pending != null ? 'Düzenle' : _actionLabel,
                icon: pending != null ? Icons.edit_outlined : Icons.add_rounded,
                color: accent,
                onPressed: vehicle == null
                    ? null
                    : () => _refillDialog(context, state, vehicle, r, pending),
              ),
              RowActionButton(
                label: 'Kontrol Et',
                icon: Icons.fact_check_outlined,
                color: AppColors.form,
                filled: false,
                onPressed: () async {
                  state.checkOil(vehicle!, r);
                  if (!context.mounted) return;
                  await showResultDialog(
                    context,
                    title: 'Kontrol Tamamlandı',
                    subtitle: formatDateTime(DateTime.now()),
                    icon: Icons.fact_check_outlined,
                    accent: AppColors.form,
                    details: <String, String>{
                      'Araç': vehicle.code,
                      _category.columnLabel: r.label,
                      'Kontrol tarihi': formatDateTime(DateTime.now()),
                    },
                    note: '${r.oilType} alanı kontrol edilmiş olarak '
                        'işaretlendi.',
                  );
                },
              ),
            ],
          ),
        ];
      },
    );
  }

  /// Satırdaki "Takviye Yap" / "Düzenle": tür satırdan geldiği için sabittir,
  /// yalnızca ürün ve miktar girilir.
  ///
  /// [pending] doluysa kayıt henüz gönderilmemiş bir takviyedir; pencere
  /// mevcut değerlerle açılır ve kullanıcı düzeltebilir ya da iptal edebilir.
  Future<void> _refillDialog(
    BuildContext context,
    AppState state,
    Vehicle vehicle,
    OilRecord record,
    PendingOperation? pending,
  ) async {
    final _RefillRequest? request = await showDialog<_RefillRequest>(
      context: context,
      builder: (BuildContext context) => _RefillDialog(
        vehicle: vehicle,
        record: record,
        category: _category,
        pending: pending,
      ),
    );

    if (request == null || !context.mounted) return;

    final String kindLabel = _manualCategory ? 'Yağlama' : 'Takviye';

    if (request.cancelled) {
      state.cancelOilRefill(pending!);
      await showResultDialog(
        context,
        title: '$kindLabel İptal Edildi',
        subtitle: formatDateTime(DateTime.now()),
        icon: Icons.delete_outline,
        accent: AppColors.emergency,
        details: <String, String>{
          'Araç': vehicle.code,
          _category.columnLabel: record.label,
        },
        note: 'Gönderilmeyi bekleyen kayıt silindi.',
      );
      return;
    }

    if (pending == null) {
      state.refillOil(vehicle, record, request.amount, product: request.product);
      await showResultDialog(
        context,
        title: '$kindLabel Kaydedildi',
        subtitle: formatDateTime(DateTime.now()),
        accent: accent,
        details: _refillDetails(vehicle, record, request),
        note: 'Kayıt gönderilmeyi bekliyor. "Gönder" ile iletebilir, '
            'göndermeden önce düzeltebilirsiniz.',
      );
      return;
    }

    state.updateOilRefill(pending, request.amount, product: request.product);
    await showResultDialog(
      context,
      title: '$kindLabel Güncellendi',
      subtitle: formatDateTime(DateTime.now()),
      icon: Icons.edit_outlined,
      accent: accent,
      details: _refillDetails(vehicle, record, request),
      note: 'Kayıt hâlâ gönderilmeyi bekliyor.',
    );
  }

  bool get _manualCategory => _category == OilCategory.manual;

  /// Sonuç penceresinde gösterilen etiket/değer satırları.
  Map<String, String> _refillDetails(
    Vehicle vehicle,
    OilRecord record,
    _RefillRequest request,
  ) {
    return <String, String>{
      'Araç': vehicle.code,
      _category.columnLabel: record.label,
      _manualCategory ? 'Kullanılan yağ miktarı' : 'Takviye miktarı':
          '${request.amount.toStringAsFixed(1)} L',
      'Kullanılan ürün': request.product,
      _manualCategory ? 'Yağlama tarihi' : 'Takviye tarihi':
          formatDateTime(DateTime.now()),
    };
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
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).pop(false);
            },
            child: const Text('Vazgeç'),
          ),
          FilledButton.icon(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).pop(true);
            },
            style: FilledButton.styleFrom(
                backgroundColor: context.accentFill(AppColors.form)),
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
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: context.brandColor, size: 42),
        title: const Text('Kontrol Tamamlandı'),
        content: Text('${records.length} alan kontrol edildi.'),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPending(
    BuildContext context,
    AppState state,
    Vehicle? vehicle,
  ) async {
    final List<PendingOperation> pending = state.pendingOf(PendingKind.oil);
    if (pending.isEmpty) return;

    final PendingSendChoice? choice =
        await showPendingSendDialog(context: context, pending: pending);

    if (choice == PendingSendChoice.discard) {
      final int discarded = state.discardPendingOil();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('$discarded işlem iptal edildi.'),
        ));
      return;
    }
    if (choice != PendingSendChoice.send) return;

    setState(() => _sending = true);
    final PublishResult result = await PublishService.instance.publishOperations(
      state: state,
      topic: PendingKind.oil.topic,
      pending: pending,
      user: state.user,
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
    state.selectVehicle(null);
    state.addNotification(
      NotificationItem(
        title: 'Yağ işlemleri gönderildi',
        message: '$count işlem${vehicle != null ? ' • ${vehicle.code}' : ''}',
        date: DateTime.now(),
        kind: NotificationKind.oil,
        vehicleCode: vehicle?.code,
        details: <String, String>{
          'İşlem': 'Yağ işlemlerinin gönderimi',
          'Gönderilen işlem sayısı': '$count',
          // Hangi işlemlerin gönderildiği sonradan da görülebilsin.
          for (int i = 0; i < pending.length; i++)
            '${i + 1}. işlem':
                '${pending[i].vehicleCode} • ${pending[i].label}',
          'Gönderim tarihi': formatDateTime(DateTime.now()),
        },
      ),
    );

    await showPendingSentDialog(context: context, sent: pending);
  }
}

/// Takviye penceresinin sonucu.
class _RefillRequest {
  const _RefillRequest(this.amount, this.product) : cancelled = false;

  /// Bekleyen takviyenin tamamen geri alınması istendi.
  const _RefillRequest.cancel()
      : amount = 0,
        product = '',
        cancelled = true;

  final double amount;

  /// Kullanılan yağ / gres ürünü (bkz. [Fleet.oilProducts]).
  final String product;

  final bool cancelled;
}

/// Tek bir satır için açılan takviye penceresi.
///
/// Tür satırdan geldiği için sabittir ve değiştirilemez; kullanıcı yalnızca
/// ürünü ve miktarı girer. [pending] verilirse pencere düzenleme kipinde
/// açılır: alanlar mevcut değerlerle dolu gelir ve kayıt iptal edilebilir.
class _RefillDialog extends StatefulWidget {
  const _RefillDialog({
    required this.vehicle,
    required this.record,
    required this.category,
    this.pending,
  });

  final Vehicle vehicle;
  final OilRecord record;
  final OilCategory category;
  final PendingOperation? pending;

  @override
  State<_RefillDialog> createState() => _RefillDialogState();
}

class _RefillDialogState extends State<_RefillDialog> {
  String? _product;
  final TextEditingController _amount = TextEditingController();

  /// Eksik alan uyarısı yalnızca kaydetmeye çalışıldıktan sonra gösterilir.
  bool _showErrors = false;

  bool get _manual => widget.category == OilCategory.manual;

  /// Gönderilmemiş bir kaydın üzerinde mi çalışıyoruz?
  bool get _editing => widget.pending != null;

  @override
  void initState() {
    super.initState();
    final PendingOperation? pending = widget.pending;
    // Yeni girişte miktar alanı boş gelir; kullanıcı kendisi girmeli.
    // Yalnızca gönderilmemiş bir kayıt düzenlenirken önceki girdi geri gelir.
    if (pending != null) {
      final double amount = (pending.payload['amount'] as num?)?.toDouble() ?? 0;
      if (amount > 0) _amount.text = amount.toStringAsFixed(1);
      final String product = (pending.payload['product'] as String?) ?? '';
      if (product.isNotEmpty) _product = product;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final String? product = _product;
    final double value =
        double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
    if (product == null || value <= 0) {
      setState(() => _showErrors = true);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(_RefillRequest(value, product));
  }

  void _cancelEntry() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(const _RefillRequest.cancel());
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
            // Tür, butona basılan satırdan gelir; burada değiştirilemez.
            InputDecorator(
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.lock_outline, size: 18),
              ),
              child: Text(
                widget.record.label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Yağ Seçin', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            // Liste alanın üstünü kapatmasın diye DropdownMenu kullanılır;
            // menü her zaman alanın altına açılır.
            DropdownMenu<String>(
              key: const ValueKey<String>('oil-product'),
              initialSelection: _product,
              requestFocusOnTap: false,
              menuHeight: 320,
              expandedInsets: EdgeInsets.zero,
              hintText: 'Kullanılan yağı seçin',
              errorText: _showErrors && _product == null
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
            if (_editing) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Bu kayıt henüz gönderilmedi; değiştirebilir veya silebilirsiniz.',
                style: TextStyle(fontSize: 12, color: context.mutedColor),
              ),
            ],
          ],
          ),
        ),
      ),
      actions: <Widget>[
        if (_editing)
          TextButton.icon(
            onPressed: _cancelEntry,
            style: TextButton.styleFrom(
                foregroundColor: context.accent(AppColors.emergency)),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Kaydı Sil'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(backgroundColor: OilScreen.accent),
          child: Text(_editing
              ? 'Değişikliği Kaydet'
              : (_manual ? 'Yağlamayı Kaydet' : 'Takviyeyi Kaydet')),
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

class _VehicleDisplay extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleDisplay({required this.vehicle, super.key});

  @override
  Widget build(BuildContext context) {
    String fallbackPath = 'assets/images/vehicle_default.png';
    final lower = vehicle.code.toLowerCase();

    if (vehicle.tirePositions.isEmpty) {
      // Paletli araçlar (Hitachi/Sany/Komatsu/yeni Liugong ekskavatörleri):
      // marka ne olursa olsun aynı jenerik görsel kullanılır.
      fallbackPath = 'assets/images/yesil_excavator.png';
    } else if (lower.startsWith('euclid')) {
      fallbackPath = 'assets/images/yesil_arac.png';
    } else if (lower.startsWith('xcmg')) {
      fallbackPath = 'assets/images/yesil_excavator.png';
    } else if (lower.startsWith('liugong')) {
      if (vehicle.tireCount <= 4) {
        fallbackPath = 'assets/images/loader.png';
      } else {
        fallbackPath = 'assets/images/green_truck.png';
      }
    }

    // Görsel, kendi tablasında durur; böylece koyu temada sayfa zemininden
    // ayrışır (bkz. [VehiclePhoto]).
    return Container(
      decoration: BoxDecoration(
        color: context.photoPlate,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: context.moduleBorderColor(OilScreen.accent)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VehicleSidePhoto(code: vehicle.code, fallbackAsset: fallbackPath),
          const SizedBox(height: 16),
          // Yağ ekranında lastik sayısının bir anlamı yok; yalnızca araç kodu
          // gösterilir.
          Text(
            vehicle.code,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
