// lib/ui/screens/tire_change_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/tire_change_model.dart';
import '../../providers/tire_change_provider.dart';
import '../../widgets/nimo_page.dart';
import '../../widgets/common.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../services/publish_service.dart';
import '../../models/models.dart' as global_models;
import '../../utils/formats.dart';
import '../../widgets/pending_send_dialog.dart';
import '../../widgets/vehicle_photo.dart';

class TireChangeScreen extends StatelessWidget {
  const TireChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NimoPage(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.pagePadding),
        child: _Body(),
      ),
    );
  }
}



// ─────────────────────────────────────────────
// BODY
// ─────────────────────────────────────────────
class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sol panel: Araç seçimi + tablo. Yağ Takviyesi ekranıyla aynı oran.
        const Expanded(
          flex: 62,
          child: _LeftPanel(),
        ),
        const SizedBox(width: 20),
        // Sağ panel: Araç fotoğrafı + gönder
        const Expanded(
          flex: 38,
          child: _RightPanel(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// SOL PANEL
// ─────────────────────────────────────────────
class _LeftPanel extends StatelessWidget {
  const _LeftPanel();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TireChangeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          const PageHeading(
            title: 'Lastik Değişimi',
            subtitle: 'Araç lastik kontrol ve değişim kayıtları',
            titleSize: 32,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _VehicleSearchField(provider: provider)),
              const SizedBox(width: 16),
              SizedBox(
                height: 50,
                child: Align(
                  alignment: Alignment.center,
                  child: _PendingSubmitButton(provider: provider),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tablo
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.isDark ? context.cardColor : context.pageColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Tablo başlıkları
                  const _TableHeader(),
                  Divider(height: 1, thickness: 1, color: context.borderColor),
                  // Tablo satırları
                  Expanded(
                    child: provider.selectedVehicle == null || provider.tireRecords.isEmpty
                        ? const EmptyState(
                            icon: Icons.tire_repair_outlined,
                            title: 'Araç seçilmedi',
                            message: 'Lastik kayıtlarını görmek için yukarıdaki "Araç Seç" alanından bir araç seçin.',
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: provider.tireRecords.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 1,
                              color: context.borderColor,
                            ),
                            itemBuilder: (context, index) {
                              final record = provider.tireRecords[index];
                              final isEditing =
                                  provider.editingTireNumber == record.tireNumber;
                              return _TireRow(
                                record: record,
                                isEditing: isEditing,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
  }
}

// ─────────────────────────────────────────────
// ARAÇ ARAMA ALANI
// ─────────────────────────────────────────────
class _VehicleSearchField extends StatefulWidget {
  final TireChangeProvider provider;
  const _VehicleSearchField({required this.provider});

  @override
  State<_VehicleSearchField> createState() => _VehicleSearchFieldState();
}

class _VehicleSearchFieldState extends State<_VehicleSearchField> {
  final TextEditingController _controller = TextEditingController();
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    // Başlangıçta seçili araç adını göster
    _controller.text = widget.provider.selectedVehicle?.name ?? '';
  }

  @override
  void didUpdateWidget(covariant _VehicleSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.provider.selectedVehicle?.name != _controller.text) {
      if (widget.provider.selectedVehicle == null) {
        _controller.clear();
      } else if (!_isOpen) {
        _controller.text = widget.provider.selectedVehicle!.name;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectVehicle(VehicleModel vehicle) {
    widget.provider.selectVehicle(vehicle);
    widget.provider.clearSearch();
    _controller.text = vehicle.name;
    setState(() => _isOpen = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.provider.filteredVehicles;

    return SizedBox(
      width: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arama kutusu
          TextField(
            controller: _controller,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Araç Seç',
              prefixIcon: const Icon(Icons.local_shipping_outlined, size: 24),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Temizle',
                      onPressed: () {
                        _controller.clear();
                        widget.provider.clearSearch();
                        widget.provider.clearSelectedVehicle();
                        setState(() => _isOpen = false);
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  const Icon(Icons.keyboard_arrow_down),
                  const SizedBox(width: 8),
                ],
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            ),
            onTap: () {
              setState(() => _isOpen = true);
              _controller.clear();
              widget.provider.clearSearch();
            },
            onChanged: (val) {
              widget.provider.updateSearch(val);
              setState(() => _isOpen = true);
            },
          ),

        // Filtreli liste (açıkken görünür)
        if (_isOpen && filtered.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: context.isDark ? context.cardColor : context.pageColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final vehicle = filtered[index];
                final isSelected =
                    widget.provider.selectedVehicle?.id == vehicle.id;
                return InkWell(
                  onTap: () => _selectVehicle(vehicle),
                  child: Container(
                    color: isSelected
                        ? context.accent(const Color(0xFF2B3252)).withValues(alpha: 0.08)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 20,
                          color: isSelected
                              ? context.accent(const Color(0xFF2B3252))
                              : context.mutedColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                vehicle.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: context.text.bodyMedium?.color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${vehicle.typeLabel} • ${vehicle.tireCount} lastik',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: context.accent(const Color(0xFF2B3252)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // Sonuç bulunamadı
        if (_isOpen && filtered.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.isDark ? context.cardColor : context.pageColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.search_off_rounded,
                    size: 16, color: context.mutedColor),
                SizedBox(width: 8),
                Text(
                  'Araç bulunamadı',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.mutedColor,
                  ),
                ),
              ],
            ),
          ),
      ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TABLO BAŞLIĞI
// ─────────────────────────────────────────────
String _getTireName(String? vehicleId, int tireNumber) {
  if (vehicleId == null) return '';
  if (vehicleId.startsWith('lodel')) {
    switch (tireNumber) {
      case 1: return 'Ön sağ';
      case 2: return 'Ön sol';
      case 3: return 'Arka sağ';
      case 4: return 'Arka sol';
      default: return '';
    }
  } else if (vehicleId.startsWith('euclid')) {
    switch (tireNumber) {
      case 1: return 'Ön sağ';
      case 2: return 'Ön sol';
      case 3: return 'Arka sağ dış';
      case 4: return 'Arka sağ iç';
      case 5: return 'Arka sol iç';
      case 6: return 'Arka sol dış';
      default: return '';
    }
  } else if (vehicleId.startsWith('liugong') || vehicleId.startsWith('xcmg')) {
    switch (tireNumber) {
      case 1: return 'Ön sağ';
      case 2: return 'Ön sol';
      case 3: return 'Arka çeker sağ dış';
      case 4: return 'Arka çeker sağ iç';
      case 5: return 'Arka çeker sol iç';
      case 6: return 'Arka çeker sol dış';
      case 7: return 'Arka taşıyıcı sağ dış';
      case 8: return 'Arka düz sağ iç';
      case 9: return 'Arka düz sol iç';
      case 10: return 'Arka düz sol dış';
      default: return '';
    }
  }
  return '';
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.isDark ? context.cardColor : context.authPanel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4, // Konum isimlerinin sığması için satır widgeti ile aynı flex
            child: Text(
              'Konum',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.mutedColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              'Seri No',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.mutedColor,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: Text(
              '',
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              'Değiştirilme Tarihi',
              textAlign: TextAlign.center,
              softWrap: false,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.mutedColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TABLO SATIRI
// ─────────────────────────────────────────────
class _TireRow extends StatefulWidget {
  final TireRecord record;
  final bool isEditing;

  const _TireRow({required this.record, required this.isEditing});

  @override
  State<_TireRow> createState() => _TireRowState();
}

class _TireRowState extends State<_TireRow>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _flashController;
  late Animation<Color?> _flashColor;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _prefillIfPending();
  }

  /// Bu oturumda girilip henüz gönderilmemiş bir seri no varsa, düzenleme
  /// alanını onunla doldurur. Böylece "Gönder"e basmadan tekrar "Değiştir"e
  /// basıldığında kullanıcı sıfırdan yazmak yerine önceki değeri düzeltir.
  /// Henüz değiştirilmemiş lastiklerde alan boş kalır; yanlışlıkla eski seri
  /// numarasının yeniymiş gibi kaydedilmesini önler.
  void _prefillIfPending() {
    if (!widget.isEditing) return;
    final String current = widget.record.serialNumber.trim();
    if (current.isEmpty || current == '---') return;
    _controller.text = current;
    _controller.selection =
        TextSelection.collapsed(offset: current.length);
  }

  /// Flash rengi temadan okunur. `Theme.of(context)` initState içinde
  /// çağrılamaz; ayrıca koyu/açık tema değişince tween yenilenmelidir.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _flashColor = ColorTween(
      begin: context.successFlash,
      end: Colors.transparent,
    ).animate(_flashController);
  }

  @override
  void didUpdateWidget(covariant _TireRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Yeni değişiklik tespit edilince yeşil flash animasyonu çal
    if (widget.record.isChanged && !oldWidget.record.isChanged) {
      _flashController.forward(from: 0);
    }
    // Düzenleme moduna her girişte alanı tazele.
    if (widget.isEditing && !oldWidget.isEditing) {
      _prefillIfPending();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TireChangeProvider>();
    // Tabloda: son aksiyon tarihi varsa onu göster, yoksa seri no değiştirilme tarihini
    final displayDate = widget.record.lastAction?.date ?? widget.record.lastChangedDate;
    final dateStr = DateFormat('dd.MM.yyyy').format(displayDate);

    return AnimatedBuilder(
      animation: _flashColor,
      builder: (context, child) {
        return Container(
          color: widget.record.isChanged
              ? _flashColor.value
              : (widget.isEditing
                  ? (context.isDark ? const Color(0xFF2C3238) : context.infoSoft)
                  : Colors.transparent),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          // height sabit 58'den kaldırıldı — Konum isimleri 2 satıra inince satır büyüsün
          child: child,
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // # kolonu — flex 4: uzun isimler için daha geniş pay
          Expanded(
            flex: 4,
            child: Text(
              '${widget.record.tireNumber}. ${_getTireName(provider.selectedVehicle?.id, widget.record.tireNumber)}',
              style: TextStyle(
                color: context.text.bodyMedium?.color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),

          // Seri No veya giriş alanı
          Expanded(
            flex: 3,
            child: widget.isEditing
                ? TextField(
                    controller: _controller,
                    autofocus: false,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      hintText: 'Yeni Seri No',
                      hintStyle: TextStyle(color: context.authHint, fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: context.accent(const Color(0xFF2B3252))),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: context.accent(const Color(0xFF2B3252)),
                            width: 2),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.text.bodyMedium?.color,
                    ),
                  )
                : Text(
                    widget.record.serialNumber,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: widget.record.isChanged
                          ? context.accent(const Color(0xFF198754))
                          : context.text.bodyMedium?.color,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),

          const SizedBox(width: 8),

          // Değiştir / Tamam / Kontrol butonu
          SizedBox(
            width: 160,
            child: widget.isEditing
                ? ElevatedButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      final String newSerial = _controller.text;
                      // Geçmiş kaydında "önceki seri no" gösterilebilsin diye
                      // değişiklik uygulanmadan önce okunur.
                      final String oldSerial = widget.record.serialNumber;
                      provider.confirmChange(widget.record.tireNumber, newSerial);
                      final state = AppScope.read(context);
                      final vehicle = provider.selectedVehicle;
                      if (vehicle != null) {
                        final DateTime now = DateTime.now();
                        // İşlem iptal edilirse geçmiş satırı da silinsin diye
                        // kuyruk kaydı ile aynı kimlik kullanılır.
                        final String activityId =
                            'tire-change-${now.microsecondsSinceEpoch}';
                        state.addPending(PendingOperation(
                          kind: PendingKind.tire,
                          vehicleCode: vehicle.name,
                          label: 'Lastik #${widget.record.tireNumber} değiştirildi ($newSerial)',
                          date: now,
                          activityId: activityId,
                          payload: <String, Object?>{
                            'op': 'lastik_degisim',
                            'tireId': 'Lastik #${widget.record.tireNumber}',
                            'position': 'Lastik ${widget.record.tireNumber}',
                            'serialNo': newSerial,
                          },
                        ));
                        state.addActivity(
                          global_models.ServiceReportActivity(
                            id: activityId,
                            vehicleCode: vehicle.name,
                            date: now,
                            reportType: 'Lastik Değişimi',
                            description: 'Lastik #${widget.record.tireNumber} değiştirildi ($newSerial)',
                            imagePaths: [],
                          ),
                        );
                        state.addNotification(
                          global_models.NotificationItem(
                            title: 'Lastik değişimi kaydedildi',
                            message: '${vehicle.name} aracı Lastik #${widget.record.tireNumber} yeni seri numarası ile değiştirildi.',
                            date: DateTime.now(),
                            kind: global_models.NotificationKind.tire,
                            vehicleCode: vehicle.name,
                            details: <String, String>{
                              'İşlem': 'Lastik değişimi',
                              'Lastik': 'Lastik #${widget.record.tireNumber}',
                              'Önceki seri numarası': oldSerial,
                              'Yeni seri numarası': newSerial,
                              'Değişim tarihi': formatDateTime(DateTime.now()),
                            },
                          ),
                        );
                      }
                      _controller.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accentFill(const Color(0xFF198754)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          provider.startEditing(widget.record.tireNumber);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.accent(const Color(0xFF2B5CE6)),
                          side: BorderSide(
                              color: context.accent(const Color(0xFF2B5CE6))),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Değiştir',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded( // Kontrol butonuna kalan boşluğu doldurt ki taşma olmasın
                        child: ElevatedButton(
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            showTireActionSheet(context, provider, widget.record, 'Lastik #${widget.record.tireNumber}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.accentFill(const Color(0xFF198754)),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Kontrol',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(width: 8),

          // Tarih
          Expanded(
            flex: 3,
            child: Text(
              dateStr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.record.isChanged
                    ? context.accent(const Color(0xFF198754))
                    : context.mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SAĞ PANEL (Animasyonlu Görsel)
// ─────────────────────────────────────────────
class _RightPanel extends StatelessWidget {
  const _RightPanel();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TireChangeProvider>();
    final vehicle = provider.selectedVehicle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
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
                    key: ValueKey(vehicle.id),
                    vehicle: vehicle,
                  ),
                ),
        ),
      ],
    );
  }
}

class _PendingSubmitButton extends StatefulWidget {
  final TireChangeProvider provider;
  const _PendingSubmitButton({required this.provider});

  @override
  State<_PendingSubmitButton> createState() => _PendingSubmitButtonState();
}

class _PendingSubmitButtonState extends State<_PendingSubmitButton> {
  bool _sending = false;

  Future<void> _sendPending(BuildContext context, AppState state, VehicleModel? vehicle) async {
    final List<PendingOperation> pending = state.pendingOf(PendingKind.tire);
    if (pending.isEmpty) return;

    final PendingSendChoice? choice =
        await showPendingSendDialog(context: context, pending: pending);

    if (choice == PendingSendChoice.discard) {
      final int discarded = state.discardPendingTire();
      await widget.provider.discardChanges();
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
      topic: PendingKind.tire.topic,
      group: PendingKind.tire.label,
      operations: <Map<String, Object?>>[
        for (final PendingOperation p in pending)
          <String, Object?>{
            ...p.payload,
            'vehicle': p.vehicleCode,
            'date': p.date.toIso8601String(),
          },
      ],
      vehicleCode: vehicle?.name,
      userRegistryNo: state.user?.registryNo,
    );
    if (!context.mounted) return;
    setState(() => _sending = false);

    if (result.success) {
      state.addNotification(
        global_models.NotificationItem(
          title: 'Lastik işlemleri gönderildi',
          message: '${pending.length} işlem${vehicle != null ? ' – ${vehicle.name}' : ''}',
          date: DateTime.now(),
          kind: global_models.NotificationKind.tire,
          vehicleCode: vehicle?.name,
          details: <String, String>{
            'İşlem': 'Lastik işlemlerinin gönderimi',
            'Gönderilen işlem sayısı': '${pending.length}',
            // Hangi işlemlerin gönderildiği sonradan da görülebilsin.
            for (int i = 0; i < pending.length; i++)
              '${i + 1}. işlem':
                  '${pending[i].vehicleCode} • ${pending[i].label}',
            'Gönderim tarihi': formatDateTime(DateTime.now()),
          },
        ),
      );
    }

    if (!result.success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Gönderilemedi: ${result.error ?? 'bilinmeyen hata'}'),
          backgroundColor: Colors.red.shade800,
        ));
      return;
    }

    final int count = pending.length;
    state.clearPending(PendingKind.tire);
    await widget.provider.resetChangedTires();
    widget.provider.clearSelectedVehicle();
    
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: context.brandColor, size: 42),
        title: const Text('İşlemler gönderildi'),
        content: SizedBox(
          width: 460,
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
              ],
            ),
          ),
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).pop();
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final int pendingCount = state.pendingCount(PendingKind.tire);

    return PrimaryActionButton(
      label: 'Gönder',
      icon: Icons.send_rounded,
      accent: AppColors.form,
      badge: pendingCount,
      compact: true,
      onPressed: pendingCount == 0 || _sending
          ? null
          : () => _sendPending(context, state, widget.provider.selectedVehicle),
    );
  }
}

class _VehicleDisplay extends StatelessWidget {
  final VehicleModel vehicle;
  const _VehicleDisplay({required this.vehicle, super.key});

  @override
  Widget build(BuildContext context) {
    // Görsel, tablodakiyle aynı mantıkta kendi tablasında durur; koyu temada
    // aracın koyu bölgeleri sayfa zeminine karışmasın diye (bkz. [VehiclePhoto]).
    return Container(
      decoration: BoxDecoration(
        color: context.photoPlate,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Aracın kendi fotoğrafı varsa marka görselinin yerine o kullanılır;
          // seçim mantığı Yağ Takviyesi ekranıyla ortaktır.
          VehicleSidePhoto(code: vehicle.name, fallbackAsset: vehicle.imagePath),
          const SizedBox(height: 16),
          Text(
            vehicle.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${vehicle.typeLabel} • ${vehicle.tireCount} lastik',
            style: TextStyle(fontSize: 13, color: context.mutedColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// POPUP (KONTROL MENÜSÜ)
// ─────────────────────────────────────────────
void showTireActionSheet(BuildContext context, TireChangeProvider provider, TireRecord record, String label) {
  showDialog(
    context: context,
    builder: (BuildContext sheetContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 700,
          child: _TireActionSheetContent(
            provider: provider,
            record: record,
            label: label,
          ),
        ),
      );
    },
  ).then((_) {
    FocusManager.instance.primaryFocus?.unfocus();
  });
}

class _TireActionSheetContent extends StatefulWidget {
  final TireChangeProvider provider;
  final TireRecord record;
  final String label;

  const _TireActionSheetContent({
    required this.provider,
    required this.record,
    required this.label,
  });

  @override
  State<_TireActionSheetContent> createState() => _TireActionSheetContentState();
}

class _TireActionSheetContentState extends State<_TireActionSheetContent> {
  bool _airChecked = false;
  bool _repairChecked = false;

  void _submit() {
    final List<String> actions = [];
    if (_airChecked) actions.add('Lastiklerin havası tamamlandı');
    if (_repairChecked) actions.add('Lastik tamiratı yapıldı');

    if (actions.isNotEmpty) {
      // setTireActions: aynı anda seçilenler aynı timestamp alır
      widget.provider.setTireActions(widget.record.tireNumber, actions);
      final state = AppScope.read(context);
      final vehicle = widget.provider.selectedVehicle;
      if (vehicle != null) {
        final DateTime now = DateTime.now();
        // İşlem iptal edilirse geçmiş satırı da silinsin diye kuyruk kaydı ile
        // aynı kimlik kullanılır.
        final String activityId = 'tire-check-${now.microsecondsSinceEpoch}';
        state.addPending(PendingOperation(
          kind: PendingKind.tire,
          vehicleCode: vehicle.name,
          label: 'Lastik #${widget.record.tireNumber} kontrol edildi',
          date: now,
          activityId: activityId,
          payload: <String, Object?>{
            'op': 'lastik_kontrol',
            'tireId': 'Lastik #${widget.record.tireNumber}',
            'position': 'Lastik ${widget.record.tireNumber}',
            'items': actions,
          },
        ));
        state.addActivity(
          global_models.ServiceReportActivity(
            id: activityId,
            vehicleCode: vehicle.name,
            date: now,
            reportType: 'Lastik Kontrolü',
            description: actions.join('\n'),
            imagePaths: [],
          ),
        );
        state.addNotification(
          global_models.NotificationItem(
            title: 'Lastik kontrolü eklendi',
            message: '${vehicle.name} aracı Lastik #${widget.record.tireNumber} kontrol edildi.',
            date: DateTime.now(),
            kind: global_models.NotificationKind.tire,
            vehicleCode: vehicle.name,
            details: <String, String>{
              'İşlem': 'Lastik kontrolü',
              'Lastik': 'Lastik #${widget.record.tireNumber}',
              'Seri numarası': widget.record.serialNumber,
              'Yapılan kontroller': actions.join(', '),
              'Kontrol tarihi': formatDateTime(DateTime.now()),
            },
          ),
        );
      }
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {


    return Container(
      decoration: BoxDecoration(
        color: context.pageColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.authBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${widget.label} Kontrolü',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.authTitle,
            ),
          ),
          const SizedBox(height: 24),

          // Tarihçe Kartı — her aksiyon kendi tarihiyle ayrı satırda
          if (widget.record.actionHistory.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: context.infoSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.accent(const Color(0xFF2B5CE6)).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history,
                          size: 22,
                          color: context.accent(const Color(0xFF2B5CE6))),
                      SizedBox(width: 8),
                      Text(
                        'Kontrol Geçmişi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.accent(const Color(0xFF2B5CE6)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Her aksiyonu kendi tarihiyle listele (en yeniden en eskiye)
                  ...widget.record.actionHistory.reversed.map((entry) {
                    final entryDate = DateFormat('dd.MM.yyyy HH:mm').format(entry.date);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              entry.action,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.authTitle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entryDate,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.mutedColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

          // Aksiyon Butonları (Checkboxes)
          Text(
            'Yeni İşlem Ekle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.mutedColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildCheckboxOption(
            title: 'Lastiklerin havası tamamlandı',
            icon: Icons.air,
            color: context.accent(const Color(0xFF198754)),
            value: _airChecked,
            onChanged: (val) {
              setState(() {
                _airChecked = val ?? false;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildCheckboxOption(
            title: 'Lastik tamiratı yapıldı',
            icon: Icons.build_circle_outlined,
            color: context.accent(const Color(0xFFF59E0B)),
            value: _repairChecked,
            onChanged: (val) {
              setState(() {
                _repairChecked = val ?? false;
              });
            },
          ),
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: (_airChecked || _repairChecked) ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.accentFill(const Color(0xFF2B5CE6)),
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  context.accentFill(const Color(0xFF2B5CE6)).withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Tamamla',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCheckboxOption({
    required String title,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color : context.authBorder,
          width: value ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: color,
        title: Row(
          children: [
            Icon(icon, size: 28, color: value ? color : context.mutedColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: value ? FontWeight.w700 : FontWeight.w600,
                  color: value ? color : context.authTitle,
                ),
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final TireChangeProvider provider;
  const _SendButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.sendSuccess) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: context.accent(const Color(0xFF198754)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Başarıyla Gönderildi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: provider.isSending ? null : () {
        final state = AppScope.of(context);
        provider.sendReport(state);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: context.accentFill(const Color(0xFF2B3252)),
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            context.accentFill(const Color(0xFF2B3252)).withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: provider.isSending
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.send_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  'Gönder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );
  }
}

