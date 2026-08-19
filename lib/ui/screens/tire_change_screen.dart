// lib/ui/screens/tire_change_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/tire_change_model.dart';
import '../../providers/tire_change_provider.dart';
import '../../widgets/nimo_page.dart';
import '../../theme/app_theme.dart';

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
        // Sol panel: Araç seçimi + tablo
        const Expanded(
          flex: 50,
          child: _LeftPanel(),
        ),
        const SizedBox(width: 20),
        // Sağ panel: Araç fotoğrafı + gönder
        const Expanded(
          flex: 50,
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
          ),
          const SizedBox(height: 16),
          _VehicleSearchField(provider: provider),
          const SizedBox(height: 20),

          // Tablo
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                  const Divider(height: 1, thickness: 1, color: Color(0xFFEEF0F5)),
                  // Tablo satırları
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: provider.tireRecords.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFEEF0F5),
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
            decoration: InputDecoration(
              hintText: 'Araç Seç',
              prefixIcon: const Icon(Icons.local_shipping_outlined, size: 20),
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
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDE1EA), width: 1.5),
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
                        ? const Color(0xFF2B3252).withValues(alpha: 0.08)
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
                              ? const Color(0xFF2B3252)
                              : const Color(0xFF7B8094),
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
                                  color: isSelected
                                      ? const Color(0xFF2B3252)
                                      : const Color(0xFF1A1D2E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${vehicle.typeLabel} • ${vehicle.tireCount} lastik',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7B8094),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Color(0xFF2B3252),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDE1EA), width: 1.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_off_rounded,
                    size: 16, color: Color(0xFF7B8094)),
                SizedBox(width: 8),
                Text(
                  'Araç bulunamadı',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7B8094),
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
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 4, // Konum isimlerinin sığması için satır widgeti ile aynı flex
            child: Text(
              'Konum',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7B8094),
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
                color: Color(0xFF7B8094),
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
                color: Color(0xFF7B8094),
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
    _flashColor = ColorTween(
      begin: const Color(0xFFD4EDDA),
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
                  ? const Color(0xFFF0F4FF)
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
              style: const TextStyle(
                color: Color(0xFF1A1D2E),
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
                    autofocus: true,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      hintText: 'Yeni Seri No',
                      hintStyle: const TextStyle(color: Color(0xFFBBC0CC), fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF2B3252)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF2B3252), width: 2),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1D2E),
                    ),
                  )
                : Text(
                    widget.record.serialNumber,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: widget.record.isChanged
                          ? const Color(0xFF198754)
                          : const Color(0xFF1A1D2E),
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
                      provider.confirmChange(
                          widget.record.tireNumber, _controller.text);
                      _controller.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF198754),
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
                          foregroundColor: const Color(0xFF2B5CE6),
                          side: const BorderSide(color: Color(0xFF2B5CE6)),
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
                            showTireActionSheet(context, provider, widget.record, 'Lastik #${widget.record.tireNumber}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF198754),
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
                    ? const Color(0xFF198754)
                    : const Color(0xFF7B8094),
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
              ? const Center(
                  child: Text(
                    'Fotoğrafı görmek için bir araç seçin',
                    style: TextStyle(color: Colors.grey),
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
          const SizedBox(height: 24),
          // Gönder Butonu
          Align(
            alignment: Alignment.bottomRight,
            child: _SendButton(provider: provider),
          ),
        ],
      );
  }
}

class _VehicleDisplay extends StatelessWidget {
  final VehicleModel vehicle;
  const _VehicleDisplay({required this.vehicle, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: Image.asset(
            vehicle.imagePath,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM SHEET (KONTROL MENÜSÜ)
// ─────────────────────────────────────────────
void showTireActionSheet(BuildContext context, TireChangeProvider provider, TireRecord record, String label) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return _TireActionSheetContent(
        provider: provider,
        record: record,
        label: label,
      );
    },
  );
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
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {


    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
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
                color: const Color(0xFFDDE1EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${widget.label} Kontrolü',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D2E),
            ),
          ),
          const SizedBox(height: 24),

          // Tarihçe Kartı — her aksiyon kendi tarihiyle ayrı satırda
          if (widget.record.actionHistory.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2B5CE6).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, size: 18, color: Color(0xFF2B5CE6)),
                      SizedBox(width: 8),
                      Text(
                        'Kontrol Geçmişi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2B5CE6),
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1D2E),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entryDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7B8094),
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
          const Text(
            'Yeni İşlem Ekle',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7B8094),
            ),
          ),
          const SizedBox(height: 12),
          _buildCheckboxOption(
            title: 'Lastiklerin havası tamamlandı',
            icon: Icons.air,
            color: const Color(0xFF198754),
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
            color: const Color(0xFFF59E0B),
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
              backgroundColor: const Color(0xFF2B5CE6),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF2B5CE6).withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Tamamla',
              style: TextStyle(
                fontSize: 16,
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
          color: value ? color : const Color(0xFFDDE1EA),
          width: value ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: color,
        title: Row(
          children: [
            Icon(icon, size: 24, color: value ? color : const Color(0xFF7B8094)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: value ? FontWeight.w700 : FontWeight.w600,
                  color: value ? color : const Color(0xFF1A1D2E),
                ),
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          color: const Color(0xFF198754),
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
      onPressed: provider.isSending ? null : () => provider.sendReport(),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2B3252),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF2B3252).withValues(alpha: 0.6),
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

