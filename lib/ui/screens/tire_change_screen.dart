// lib/ui/screens/tire_change_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../widgets/result_dialog.dart';
import '../../widgets/vehicle_photo.dart';
import '../../widgets/vehicle_type_filter.dart';

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
        const Expanded(flex: 62, child: _LeftPanel()),
        const SizedBox(width: 20),
        // Sağ panel: Araç fotoğrafı + gönder
        const Expanded(flex: 38, child: _RightPanel()),
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
              border: Border.all(
                color: context.moduleBorderColor(AppColors.tire),
                width: 2.5,
              ),
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
                  child:
                      provider.selectedVehicle == null ||
                          provider.tireRecords.isEmpty
                      ? const EmptyState(
                          icon: Icons.tire_repair_outlined,
                          title: 'Araç seçilmedi',
                          message:
                              'Lastik kayıtlarını görmek için yukarıdaki "Araç Seç" alanından bir araç seçin.',
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
                            return _TireRow(
                              record: provider.tireRecords[index],
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
  final FocusNode _focusNode = FocusNode();
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  /// Liste açık mı? Odaklanınca açılır, seçim yapılınca veya odak
  /// kaybedilince kapanır.
  bool _isOpen = false;

  String _selectedLabel() {
    final VehicleModel? selected = widget.provider.selectedVehicle;
    return selected == null ? '' : widget.provider.displayNameOf(selected);
  }

  @override
  void initState() {
    super.initState();
    // Başlangıçta seçili araç adını göster
    _controller.text = _selectedLabel();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _VehicleSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedLabel() != _controller.text) {
      if (widget.provider.selectedVehicle == null) {
        _controller.clear();
      } else if (!_isOpen) {
        _controller.text = _selectedLabel();
      }
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      // Odaklanınca tüm liste görünsün.
      setState(() => _isOpen = true);
      _controller.clear();
      widget.provider.clearSearch();
      _showOverlay();
    } else {
      setState(() => _isOpen = false);
      _removeOverlay();
      final VehicleModel? selected = widget.provider.selectedVehicle;
      _controller.text = selected == null
          ? ''
          : widget.provider.displayNameOf(selected);
    }
  }

  void _showOverlay() {
    if (_entry != null) return;
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_entry!);
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  void _selectVehicle(VehicleModel vehicle) {
    widget.provider.selectVehicle(vehicle);
    widget.provider.clearSearch();
    _controller.text = widget.provider.displayNameOf(vehicle);
    setState(() => _isOpen = false);
    _removeOverlay();
    FocusScope.of(context).unfocus();
  }

  /// Metin alanının hemen altında, sayfa akışını itmeden açılan yüzen liste.
  /// Diğer araç seçim alanlarıyla ([VehicleSelector]) aynı yaklaşım: liste
  /// tabloyu aşağı kaydırmaz, üstüne biner.
  Widget _buildOverlay(BuildContext overlayContext) {
    return Stack(
      children: <Widget>[
        // Dışarı tıklayınca listeyi kapat.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _focusNode.unfocus(),
          ),
        ),
        Positioned(
          width: 420,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: const Offset(0, 60),
            // Liste, metin alanının dokunma bölgesinin parçası sayılır; aksi
            // halde fare tuşuna basıldığı anda alan odağı kaybeder ve tıklama
            // tamamlanmadan satır ağaçtan silinir.
            child: TextFieldTapRegion(
              child: Material(
                color: Colors.transparent,
                // Liste kendini sağlayıcıyı dinleyerek tazeler. Elle
                // markNeedsBuild() çağırmak, yapım (build) aşamasında
                // tetiklenirse Flutter hata veriyor.
                child: ListenableBuilder(
                  listenable: widget.provider,
                  builder: (BuildContext context, Widget? _) {
                    final List<VehicleModel> filtered =
                        widget.provider.filteredVehicles;
                    return _buildResultsPanel(context, filtered);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tip filtresi + sonuç listesi (ya da "sonuç yok" satırı). Filtre satırı
  /// liste boşken de görünür kalır ki kullanıcı seçimi geri alabilsin.
  Widget _buildResultsPanel(BuildContext context, List<VehicleModel> filtered) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: BoxDecoration(
        color: context.isDark ? context.cardColor : context.pageColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.moduleBorderColor(AppColors.tire),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          VehicleTypeFilter(
            categories: widget.provider.vehicleCategories,
            selected: widget.provider.typeFilter,
            accent: AppColors.tire,
            onChanged: widget.provider.setTypeFilter,
          ),
          Divider(height: 1, color: context.borderColor),
          Flexible(
            child: filtered.isEmpty
                ? _buildEmptyResult(context)
                : _buildResultsList(context, filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, List<VehicleModel> filtered) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final vehicle = filtered[index];
        final isSelected = widget.provider.selectedVehicle?.id == vehicle.id;
        return InkWell(
          onTap: () => _selectVehicle(vehicle),
          child: Container(
            color: isSelected
                ? context
                      .accent(const Color(0xFF2B3252))
                      .withValues(alpha: 0.08)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.local_shipping_outlined,
                  size: 24,
                  color: isSelected
                      ? context.accent(const Color(0xFF2B3252))
                      : context.mutedColor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.provider.displayNameOf(vehicle),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.text.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${vehicle.typeLabel} • ${vehicle.tireCount} lastik',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: context.accent(const Color(0xFF2B3252)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyResult(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.search_off_rounded, size: 16, color: context.mutedColor),
          const SizedBox(width: 8),
          Text(
            'Araç bulunamadı',
            style: TextStyle(fontSize: 14, color: context.mutedColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: CompositedTransformTarget(
        link: _link,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
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
                      _removeOverlay();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                const Icon(Icons.keyboard_arrow_down),
                const SizedBox(width: 8),
              ],
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.moduleBorderColor(AppColors.tire),
                width: 1.5,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.moduleBorderColor(AppColors.tire),
                width: 1.5,
              ),
            ),
          ),
          onChanged: (val) {
            widget.provider.updateSearch(val);
            setState(() => _isOpen = true);
            _showOverlay();
          },
        ),
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
      case 1:
        return 'Ön sağ';
      case 2:
        return 'Ön sol';
      case 3:
        return 'Arka sağ';
      case 4:
        return 'Arka sol';
      default:
        return '';
    }
  } else if (vehicleId.startsWith('euclid')) {
    switch (tireNumber) {
      case 1:
        return 'Ön sağ';
      case 2:
        return 'Ön sol';
      case 3:
        return 'Arka sağ dış';
      case 4:
        return 'Arka sağ iç';
      case 5:
        return 'Arka sol iç';
      case 6:
        return 'Arka sol dış';
      default:
        return '';
    }
  } else if (vehicleId.startsWith('liugong') || vehicleId.startsWith('xcmg')) {
    switch (tireNumber) {
      case 1:
        return 'Ön sağ';
      case 2:
        return 'Ön sol';
      case 3:
        return 'Arka çeker sağ dış';
      case 4:
        return 'Arka çeker sağ iç';
      case 5:
        return 'Arka çeker sol iç';
      case 6:
        return 'Arka çeker sol dış';
      case 7:
        return 'Arka taşıyıcı sağ dış';
      case 8:
        return 'Arka düz sağ iç';
      case 9:
        return 'Arka düz sol iç';
      case 10:
        return 'Arka düz sol dış';
      default:
        return '';
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
            flex:
                4, // Konum isimlerinin sığması için satır widgeti ile aynı flex
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
          Expanded(
            flex: 2,
            child: Text(
              'Basınç',
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
          Expanded(
            flex: 3,
            child: Text(
              'Marka',
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
            width: _actionsWidth,
            child: Text('', textAlign: TextAlign.center),
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

  const _TireRow({required this.record});

  @override
  State<_TireRow> createState() => _TireRowState();
}

class _TireRowState extends State<_TireRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<Color?> _flashColor;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
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
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  Widget _cell(String text, {bool highlight = false, double size = 14}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: highlight
            ? context.accent(const Color(0xFF198754))
            : context.text.bodyMedium?.color,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TireChangeProvider>();
    final TireRecord record = widget.record;
    // Tabloda: son aksiyon tarihi varsa onu göster, yoksa seri no değiştirilme tarihini
    final displayDate = record.lastAction?.date ?? record.lastChangedDate;
    final dateStr = DateFormat('dd.MM.yyyy').format(displayDate);
    final bool hasTire =
        record.hasInitialRecord && record.serialNumber != '---';
    final String position =
        '${record.tireNumber}. ${_getTireName(provider.selectedVehicle?.id, record.tireNumber)}';

    return AnimatedBuilder(
      animation: _flashColor,
      builder: (context, child) {
        return Container(
          color: record.isChanged ? _flashColor.value : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: child,
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              position,
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
          Expanded(
            flex: 3,
            child: _cell(
              record.serialNumber,
              highlight: record.isChanged,
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _cell(
              hasTire ? formatTirePressure(record.pressure) : '---',
              highlight: record.isChanged,
              size: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _cell(
              hasTire && record.brand.isNotEmpty ? record.brand : '---',
              highlight: record.isChanged,
              size: 13,
            ),
          ),
          const SizedBox(width: 8),

          // İlk lastik kaydı / Değiştir / Kontrol / Önceki Lastik butonları.
          // Yazı tipi cihaza göre değiştiği için butonlar sığmazsa taşmak
          // yerine birlikte küçülür.
          SizedBox(
            width: _actionsWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!hasTire) ...[
                    OutlinedButton(
                      onPressed: () =>
                          _openMountDialog(context, record, initial: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD97706),
                        side: const BorderSide(
                          color: Color(0xFFD97706),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'İlk lastik kaydı',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  OutlinedButton(
                    onPressed: () =>
                        _openMountDialog(context, record, initial: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.accent(const Color(0xFF2B5CE6)),
                      side: BorderSide(
                        color: context.accent(const Color(0xFF2B5CE6)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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
                  ElevatedButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      showTireActionSheet(
                        context,
                        provider,
                        record,
                        'Lastik #${record.tireNumber}',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accentFill(
                        const Color(0xFF198754),
                      ),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
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
                  // Sökülmüş lastik varsa: o an takılı olandan bir önceki lastik.
                  // Bu durumda "İlk lastik kaydı" görünmediği için yer açıktır.
                  if (record.previousTires.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    // "Kontrol" ile aynı tip, ölçü ve renk.
                    ElevatedButton(
                      onPressed: () =>
                          showPreviousTireDialog(context, record, position),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.accentFill(const Color(0xFF198754)),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Önceki Lastik',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
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
                color: record.isChanged
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

/// Satırdaki işlem butonlarının alanı; başlıkta da aynı genişlik kullanılır.
const double _actionsWidth = 300;

/// Değişimde gönderilen sökülen lastik alanları.
const List<String> _previousTireKeys = <String>[
  'previousSerialNo',
  'previousPressure',
  'previousBrand',
  'previousCoating',
  'previousMountedAt',
  'previousRemovedAt',
];

/// Bu lastik için henüz gönderilmemiş takma işlemi (ilk kayıt ya da değişim).
PendingOperation? _pendingMountFor(
  AppState state,
  VehicleModel vehicle,
  int tireNumber,
) {
  for (final PendingOperation p in state.pendingOf(PendingKind.tire)) {
    if (p.vehicleCode != vehicle.name) continue;
    if (p.payload['tireId'] != 'Lastik #$tireNumber') continue;
    final Object? op = p.payload['op'];
    if (op == 'ilk_kayit' || op == 'degisim') return p;
  }
  return null;
}

/// "İlk lastik kaydı" ya da "Değiştir": bilgileri pencereden alır, kaydı
/// günceller ve gönderim kuyruğuna ekler. Gönderilmemiş bir giriş tekrar
/// açılırsa yeni işlem eklenmez, mevcut olan düzeltilir.
Future<void> _openMountDialog(
  BuildContext context,
  TireRecord record, {
  required bool initial,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final TireChangeProvider provider = context.read<TireChangeProvider>();
  final AppState state = AppScope.read(context);
  final VehicleModel? vehicle = provider.selectedVehicle;
  if (vehicle == null) return;

  final PendingOperation? pending = record.isChanged
      ? _pendingMountFor(state, vehicle, record.tireNumber)
      : null;
  // Gönderilmemiş girişin türü korunur (ilk kayıt düzeltilirken değişime
  // dönmesin).
  final bool isInitial = pending != null
      ? pending.payload['op'] == 'ilk_kayit'
      : initial;
  final String position = _getTireName(vehicle.id, record.tireNumber);

  final _TireMountInput? input = await showDialog<_TireMountInput>(
    context: context,
    builder: (_) => _TireMountDialog(
      vehicleName: provider.displayNameOf(vehicle),
      positionLabel: '${record.tireNumber}. $position',
      initial: isInitial,
      record: record,
      editingPending: pending != null,
    ),
  );
  if (input == null) return;

  // "Değiştir" ile kayıtlı lastiği olmayan bir konuma takılırsa sökülen
  // lastik bilinmez; önceki lastik bilgileri gönderilmez.
  final bool hadTire = record.hasInitialRecord && record.serialNumber != '---';

  await provider.mountTire(
    record.tireNumber,
    serialNumber: input.serialNumber,
    pressure: input.pressure,
    brand: input.brand,
    coated: input.coated,
    replacesPending: pending != null,
  );

  final DateTime now = DateTime.now();
  final String opTitle = isInitial ? 'İlk Lastik Kaydı' : 'Lastik Değişimi';
  final String opLabel = isInitial
      ? 'Lastik #${record.tireNumber} ilk kaydı yapıldı (${input.serialNumber})'
      : 'Lastik #${record.tireNumber} değiştirildi (${input.serialNumber})';
  final Map<String, Object?> payload = <String, Object?>{
    'op': isInitial ? 'ilk_kayit' : 'degisim',
    'tireId': 'Lastik #${record.tireNumber}',
    'position': position,
    'serialNo': input.serialNumber,
    'pressure': input.pressure,
    'pressureUnit': tirePressureUnit,
    'brand': input.brand,
    // Web paneli lastik başına kaplama sayısını bu 1/0 değerlerini toplayarak
    // hesaplar.
    'coating': input.coated ? 1 : 0,
    // Sökülen lastiğin bilgileri. Düzeltmede ilk girişteki değerler korunur;
    // aksi halde düzeltilen giriş "sökülen lastik" gibi görünürdü.
    if (!isInitial && pending != null) ...<String, Object?>{
      for (final String key in _previousTireKeys)
        if (pending.payload.containsKey(key)) key: pending.payload[key],
    } else if (!isInitial && hadTire) ...<String, Object?>{
      'previousSerialNo': record.serialNumber,
      'previousPressure': record.pressure,
      'previousBrand': record.brand,
      'previousCoating': record.coated == null
          ? null
          : (record.coated! ? 1 : 0),
      'previousMountedAt': record.lastChangedDate.toUtc().toIso8601String(),
      'previousRemovedAt': now.toUtc().toIso8601String(),
    },
  };

  if (pending != null) {
    state.replacePending(
      pending.copyWith(label: opLabel, date: now, payload: payload),
    );
  } else {
    final String activityId = 'tire-change-${now.microsecondsSinceEpoch}';
    state.addPending(
      PendingOperation(
        kind: PendingKind.tire,
        vehicleCode: vehicle.name,
        label: opLabel,
        date: now,
        activityId: activityId,
        payload: payload,
      ),
    );
    state.addActivity(
      global_models.ServiceReportActivity(
        id: activityId,
        vehicleCode: vehicle.name,
        date: now,
        reportType: opTitle,
        description: opLabel,
        imagePaths: [],
      ),
    );
  }
  state.addNotification(
    global_models.NotificationItem(
      title: '$opTitle kaydedildi',
      message:
          '${provider.displayNameOf(vehicle)} aracı Lastik #${record.tireNumber}: '
          '${input.serialNumber} • ${input.brand} • ${formatTirePressure(input.pressure)}',
      date: now,
      kind: global_models.NotificationKind.tire,
      vehicleCode: vehicle.name,
      details: <String, String>{
        'İşlem': opTitle,
        'Lastik': 'Lastik #${record.tireNumber} ($position)',
        'Seri numarası': input.serialNumber,
        'Hava basıncı': formatTirePressure(input.pressure),
        'Lastik markası': input.brand,
        'Kaplama yapıldı mı': input.coated ? 'Evet' : 'Hayır',
        if (payload['previousSerialNo'] != null)
          'Sökülen lastik': '${payload['previousSerialNo']}',
        'Tarih': formatDateTime(now),
      },
    ),
  );
}

/// Pencereden dönen lastik bilgileri.
class _TireMountInput {
  const _TireMountInput(
    this.serialNumber,
    this.pressure,
    this.brand,
    this.coated,
  );

  final String serialNumber;
  final double pressure;
  final String brand;

  /// Takılan lastiğe bu işlemde kaplama yapıldı mı?
  final bool coated;
}

/// Lastik takma penceresi: seri no, hava basıncı ve marka.
class _TireMountDialog extends StatefulWidget {
  const _TireMountDialog({
    required this.vehicleName,
    required this.positionLabel,
    required this.initial,
    required this.record,
    required this.editingPending,
  });

  final String vehicleName;
  final String positionLabel;

  /// İlk lastik kaydı mı, değişim mi?
  final bool initial;
  final TireRecord record;

  /// Gönderilmemiş bir giriş mi düzeltiliyor?
  final bool editingPending;

  @override
  State<_TireMountDialog> createState() => _TireMountDialogState();
}

class _TireMountDialogState extends State<_TireMountDialog> {
  /// Sahada kullanilan lastik markalari. Kullanici elle yazmaz, bu listeden
  /// secer; boylece panele her seferinde ayni yazim gider.
  static const List<String> _brands = <String>[
    'Doublecoin',
    'Brigestone',
    'Michelin',
    'Tıanlı',
    'Bkt',
  ];

  final TextEditingController _serial = TextEditingController();
  final TextEditingController _pressure = TextEditingController();

  /// Secili marka; secilmeden kaydedilemez.
  String? _brand;

  /// Eksik alan uyarısı yalnızca kaydetmeye çalışıldıktan sonra gösterilir.
  bool _showErrors = false;

  /// "Kaplama yapıldı mı?" cevabı; seçilmeden kaydedilemez.
  bool? _coated;

  /// Değişimde sökülecek lastik. Gönderilmemiş bir giriş düzeltiliyorsa
  /// sökülen lastik o girişten önceki lastiktir. Konumda kayıtlı lastik
  /// yoksa `null`.
  TireMount? get _removedTire {
    if (widget.initial) return null;
    if (widget.editingPending) {
      return widget.record.previousTires.isEmpty
          ? null
          : widget.record.previousTires.last;
    }
    if (!widget.record.hasInitialRecord ||
        widget.record.serialNumber == '---') {
      return null;
    }
    return TireMount(
      serialNumber: widget.record.serialNumber,
      pressure: widget.record.pressure,
      brand: widget.record.brand,
      mountedAt: widget.record.lastChangedDate,
      removedAt: DateTime.now(),
    );
  }

  @override
  void initState() {
    super.initState();
    // Yeni girişte alanlar boş gelir. Yalnızca gönderilmemiş bir giriş
    // düzeltilirken önceki değerler geri gelir.
    if (widget.editingPending) {
      _serial.text = widget.record.serialNumber;
      final double? p = widget.record.pressure;
      if (p != null) _pressure.text = formatTirePressure(p).split(' ').first;
      // Elle yazilmis eski kayitlarda marka listede olmayabilir; o zaman
      // kullanici yeniden secer.
      final String saved = widget.record.brand.trim();
      _brand = _brands.contains(saved) ? saved : null;
      _coated = widget.record.coated;
    }
  }

  @override
  void dispose() {
    _serial.dispose();
    _pressure.dispose();
    super.dispose();
  }

  double? get _pressureValue =>
      double.tryParse(_pressure.text.trim().replaceAll(',', '.'));

  String? get _serialError {
    final String serial = _serial.text.trim();
    if (serial.isEmpty) return 'Seri numarasını girin.';
    final TireMount? removed = _removedTire;
    if (removed != null && serial == removed.serialNumber) {
      return 'Yeni lastiğin seri numarası sökülen lastikle aynı olamaz.';
    }
    return null;
  }

  String? get _pressureError {
    final double? p = _pressureValue;
    if (p == null || p <= 0) return 'Hava basıncını girin.';
    return null;
  }

  String? get _brandError => _brand == null ? 'Lastik markasını seçin.' : null;

  void _save() {
    final bool? coated = _coated;
    if (_serialError != null ||
        _pressureError != null ||
        _brandError != null ||
        coated == null) {
      setState(() => _showErrors = true);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(
      _TireMountInput(_serial.text.trim(), _pressureValue!, _brand!, coated),
    );
  }

  /// Marka secim butonu. Kaplama secimiyle ayni gorsel dil; tek farki
  /// genislige gore sarmasi (bes secenek var).
  Widget _brandChoice(String brand) {
    final bool selected = _brand == brand;
    final Color tone = context.accent(const Color(0xFF2B3252));
    return OutlinedButton(
      onPressed: () => setState(() => _brand = brand),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? tone.withValues(alpha: 0.12) : null,
        foregroundColor: selected ? tone : context.text.bodyMedium?.color,
        side: BorderSide(
          color: selected
              ? tone
              : (_showErrors && _brand == null
                    ? context.accent(AppColors.emergency)
                    : context.borderColor),
          width: selected ? 2 : 1,
        ),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            brand,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _coatingChoice(String label, bool value) {
    final bool selected = _coated == value;
    final Color tone = context.accent(const Color(0xFF198754));
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _coated = value),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? tone.withValues(alpha: 0.12) : null,
          foregroundColor: selected ? tone : context.text.bodyMedium?.color,
          side: BorderSide(
            color: selected
                ? tone
                : (_showErrors && _coated == null
                      ? context.accent(AppColors.emergency)
                      : context.borderColor),
            width: selected ? 2 : 1,
          ),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _revalidate(String _) {
    if (_showErrors) setState(() {});
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13)),
  );

  @override
  Widget build(BuildContext context) {
    final TireMount? removed = _removedTire;
    return AlertDialog(
      title: Text(widget.initial ? 'İlk Lastik Kaydı' : 'Lastik Değişimi'),
      content: SizedBox(
        width: 460,
        // Küçük tablette pencere taşmasın diye kaydırılır.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.vehicleName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              _label('Lastik konumu'),
              // Konum, butona basılan satırdan gelir; burada değiştirilemez.
              InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.lock_outline, size: 18),
                ),
                child: Text(
                  widget.positionLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (removed != null) ...<Widget>[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.infoSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Sökülecek lastik',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.accent(const Color(0xFF2B5CE6)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      InfoLine(
                        label: 'Seri No',
                        value: removed.serialNumber,
                        labelWidth: 120,
                      ),
                      InfoLine(
                        label: 'Hava basıncı',
                        value: formatTirePressure(removed.pressure),
                        labelWidth: 120,
                      ),
                      InfoLine(
                        label: 'Marka',
                        value: removed.brand.isEmpty ? '---' : removed.brand,
                        labelWidth: 120,
                      ),
                      InfoLine(
                        label: 'Takılma tarihi',
                        value: formatDateTime(removed.mountedAt),
                        labelWidth: 120,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _label(
                widget.initial
                    ? 'Lastik seri numarası'
                    : 'Yeni lastiğin seri numarası',
              ),
              TextField(
                controller: _serial,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Seri numarasını girin',
                  errorText: _showErrors ? _serialError : null,
                ),
                onChanged: _revalidate,
              ),
              const SizedBox(height: 16),
              _label('Hava basıncı ($tirePressureUnit)'),
              TextField(
                controller: _pressure,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  hintText: 'Basılan hava basıncı',
                  suffixText: tirePressureUnit,
                  errorText: _showErrors ? _pressureError : null,
                ),
                onChanged: _revalidate,
              ),
              const SizedBox(height: 16),
              _label('Lastik markası'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for (final String brand in _brands) _brandChoice(brand),
                ],
              ),
              if (_showErrors && _brandError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    _brandError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.accent(AppColors.emergency),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _label('Kaplama yapıldı mı?'),
              Row(
                children: <Widget>[
                  _coatingChoice('Evet', true),
                  const SizedBox(width: 12),
                  _coatingChoice('Hayır', false),
                ],
              ),
              if (_showErrors && _coated == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    'Kaplama yapılıp yapılmadığını seçin.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              InfoLine(
                label: widget.initial ? 'Kayıt tarihi' : 'Değişim tarihi',
                value: formatDateTime(DateTime.now()),
                labelWidth: 120,
              ),
              if (widget.editingPending) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Bu kayıt henüz gönderilmedi; bilgileri düzeltebilirsiniz.',
                  style: TextStyle(fontSize: 12, color: context.mutedColor),
                ),
              ],
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
          style: FilledButton.styleFrom(
            backgroundColor: context.accentFill(const Color(0xFF198754)),
          ),
          child: Text(
            widget.initial ? 'İlk Lastik Kaydını Kaydet' : 'Değişimi Kaydet',
          ),
        ),
      ],
    );
  }
}

/// Bir lastik konumundan en son sökülen lastik: o an takılı olandan bir
/// önceki lastik. "Geçmiş" kayıt detayıyla aynı pencere düzeni kullanılır.
void showPreviousTireDialog(
  BuildContext context,
  TireRecord record,
  String position,
) {
  final TireMount previous = record.previousTires.last;
  final TireChangeProvider provider = context.read<TireChangeProvider>();
  final VehicleModel? vehicle = provider.selectedVehicle;
  final bool? coated = previous.coated;
  showResultDialog(
    context,
    title: 'Önceki Lastik',
    subtitle: vehicle == null
        ? position
        : '${provider.displayNameOf(vehicle)} • $position',
    icon: Icons.history,
    accent: AppColors.tire,
    detailsTitle: 'Lastik bilgileri',
    details: <String, String>{
      'Lastik seri no': previous.serialNumber,
      'Lastik basıncı': formatTirePressure(previous.pressure),
      'Lastik markası': previous.brand.isEmpty ? '---' : previous.brand,
      'Takıldığı tarih': formatDateTime(previous.mountedAt),
      'Çıkartıldığı tarih': formatDateTime(previous.removedAt),
      'Kaplama yapıldı mı': coated == null ? 'Bilinmiyor' : (coated ? 'Evet' : 'Hayır'),
    },
  );
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

  Future<void> _sendPending(
    BuildContext context,
    AppState state,
    VehicleModel? vehicle,
  ) async {
    final List<PendingOperation> pending = state.pendingOf(PendingKind.tire);
    if (pending.isEmpty) return;

    final PendingSendChoice? choice = await showPendingSendDialog(
      context: context,
      pending: pending,
      unmatchedVehicles: state.unmatchedVehicleCodes,
    );

    if (choice == PendingSendChoice.discard) {
      final int discarded = state.discardPendingTire();
      await widget.provider.discardChanges();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('$discarded işlem iptal edildi.')),
        );
      return;
    }
    if (choice != PendingSendChoice.send) return;

    setState(() => _sending = true);
    final PublishResult result = await PublishService.instance
        .publishOperations(
          state: state,
          topic: PendingKind.tire.topic,
          pending: pending,
          user: state.user,
        );
    if (!context.mounted) return;
    setState(() => _sending = false);

    if (result.success) {
      state.addNotification(
        global_models.NotificationItem(
          title: 'Lastik işlemleri gönderildi',
          message:
              '${pending.length} işlem${vehicle != null ? ' – ${widget.provider.displayNameOf(vehicle)}' : ''}',
          date: DateTime.now(),
          kind: global_models.NotificationKind.tire,
          vehicleCode: vehicle?.name,
          details: <String, String>{
            'İşlem': 'Lastik işlemlerinin gönderimi',
            'Gönderilen işlem sayısı': '${pending.length}',
            // Hangi işlemlerin gönderildiği sonradan da görülebilsin.
            for (int i = 0; i < pending.length; i++)
              '${i + 1}. işlem':
                  '${AppScope.read(context).displayNameFor(pending[i].vehicleCode)} • ${pending[i].label}',
            'Gönderim tarihi': formatDateTime(DateTime.now()),
          },
        ),
      );
    }

    if (!result.success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Gönderilemedi: ${result.error ?? 'bilinmeyen hata'}',
            ),
            backgroundColor: Colors.red.shade800,
          ),
        );
      return;
    }

    state.clearPending(PendingKind.tire);
    await widget.provider.resetChangedTires();
    widget.provider.clearSelectedVehicle();

    await showPendingSentDialog(context: context, sent: pending);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final int pendingCount = state.pendingCount(PendingKind.tire);

    return PrimaryActionButton(
      label: 'Gönder',
      icon: Icons.send_rounded,
      accent: AppColors.tire,
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
        border: Border.all(
          color: context.moduleBorderColor(AppColors.tire),
          width: 2.5,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Aracın kendi fotoğrafı varsa marka görselinin yerine o kullanılır;
          // seçim mantığı Yağ Takviyesi ekranıyla ortaktır.
          VehicleSidePhoto(
            code: vehicle.name,
            fallbackAsset: vehicle.imagePath,
          ),
          const SizedBox(height: 16),
          Text(
            context.watch<TireChangeProvider>().displayNameOf(vehicle),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${vehicle.typeLabel} • ${vehicle.tireCount} lastik',
            style: TextStyle(fontSize: 16, color: context.mutedColor),
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
void showTireActionSheet(
  BuildContext context,
  TireChangeProvider provider,
  TireRecord record,
  String label,
) {
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
  State<_TireActionSheetContent> createState() =>
      _TireActionSheetContentState();
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
        state.addPending(
          PendingOperation(
            kind: PendingKind.tire,
            vehicleCode: vehicle.name,
            label: 'Lastik #${widget.record.tireNumber} kontrol edildi',
            date: now,
            activityId: activityId,
            payload: <String, Object?>{
              'op': 'kontrol',
              'tireId': 'Lastik #${widget.record.tireNumber}',
              'position': _getTireName(vehicle.id, widget.record.tireNumber),
              'serialNo': widget.record.serialNumber,
              // İki kontrol türü ayrı ayrı gönderilir; işaretlenmeyen de
              // `false` olarak gider ki panelde ikisinin durumu da görünsün.
              'airCompleted': _airChecked,
              'repairDone': _repairChecked,
            },
          ),
        );
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
            message:
                '${widget.provider.displayNameOf(vehicle)} aracı Lastik #${widget.record.tireNumber} kontrol edildi.',
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
                border: Border.all(
                  color: context
                      .accent(const Color(0xFF2B5CE6))
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 22,
                        color: context.accent(const Color(0xFF2B5CE6)),
                      ),
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
                    final entryDate = DateFormat(
                      'dd.MM.yyyy HH:mm',
                    ).format(entry.date);
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
              disabledBackgroundColor: context
                  .accentFill(const Color(0xFF2B5CE6))
                  .withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Tamamla',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
      onPressed: provider.isSending
          ? null
          : () {
              final state = AppScope.of(context);
              provider.sendReport(state);
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: context.accentFill(const Color(0xFF2B3252)),
        foregroundColor: Colors.white,
        disabledBackgroundColor: context
            .accentFill(const Color(0xFF2B3252))
            .withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
    );
  }
}
