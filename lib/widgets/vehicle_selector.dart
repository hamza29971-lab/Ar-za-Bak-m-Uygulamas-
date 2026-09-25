import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'vehicle_type_filter.dart';

/// "Araç Seç" alanı.
/// - Tıklandığında tüm araçlar aşağı doğru listelenir.
/// - Yazıldıkça liste karakterlere göre filtrelenir.
/// - Listeden seçilen araç yukarı taşınır.
class VehicleSelector extends StatefulWidget {
  const VehicleSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.accentColor,
    this.borderAccent,
    this.width = 420,
  });

  final Vehicle? selected;
  final ValueChanged<Vehicle?> onSelected;
  final Color? accentColor;

  /// Kenarlık rengi. Verilmezse [accentColor] kullanılır; modül renginden
  /// farklı bir kenarlık isteniyorsa (ör. Mekanik Operasyon'da mavi
  /// kenarlık) buradan verilir.
  final Color? borderAccent;
  final double width;

  @override
  State<VehicleSelector> createState() => _VehicleSelectorState();
}

class _VehicleSelectorState extends State<VehicleSelector> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  /// Kullanıcı arama yazmaya başladı mı? Başlamadıysa (ör. alana yeni tıklandı)
  /// seçili aracın kodu filtre olarak kullanılmaz, tüm liste gösterilir.
  bool _typing = false;

  /// Seçili araç kategorisi (`Kamyon`/`Ekskavatör`/`Loder`); `null` ise tümü.
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.selected?.code ?? '';
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant VehicleSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected?.id != oldWidget.selected?.id && !_focusNode.hasFocus) {
      _controller.text = widget.selected?.code ?? '';
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
      // Odaklanınca tüm liste görünsün: metin seçili hale gelir, yazılan ilk
      // karakter mevcut kodun yerini alır.
      _typing = false;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      _showOverlay();
    } else {
      _typing = false;
      _removeOverlay();
      final Vehicle? selected = widget.selected;
      if (selected != null) _controller.text = selected.code;
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

  void _select(Vehicle vehicle) {
    _typing = false;
    _controller.text = vehicle.code;
    widget.onSelected(vehicle);
    _focusNode.unfocus();
    _removeOverlay();
  }

  void _clear() {
    _typing = false;
    _controller.clear();
    widget.onSelected(null);
    setState(() {});
    _entry?.markNeedsBuild();
  }

  /// Kenarlıklarda kullanılan renk; verilmemişse vurgu rengine düşer.
  Color? get _edge => widget.borderAccent ?? widget.accentColor;

  Widget _buildOverlay(BuildContext overlayContext) {
    final AppState state = AppScope.read(context);
    final List<Vehicle> items = state
        .filterVehicles(_typing ? _controller.text : '')
        .where((Vehicle v) => _typeFilter == null || v.category == _typeFilter)
        .toList();
    final List<String> categories = <String>[
      for (final String c in vehicleCategoryOrder)
        if (state.vehicles.any((Vehicle v) => v.category == c)) c,
    ];
    final Color accent =
        widget.accentColor ?? Theme.of(context).colorScheme.primary;

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
          width: widget.width,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            // Liste, metin alanının dokunma bölgesinin parçası sayılır. Aksi
            // halde fare tuşuna basıldığı anda alan odağı kaybeder, liste
            // kaldırılır ve tuş bırakılmadan satır ağaçtan silindiği için
            // tıklama hiç tamamlanmaz (masaüstünde seçim yapılamaz).
            child: TextFieldTapRegion(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 420),
                  decoration: BoxDecoration(
                    color:
                        context.isDark ? context.elevatedColor : context.pageColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _edge != null
                          ? context.moduleBorderColor(_edge!)
                          : context.borderColor,
                      width: 2.5,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: context.isDark ? 0.4 : 0.08,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      VehicleTypeFilter(
                        categories: categories,
                        selected: _typeFilter,
                        accent: _edge ?? accent,
                        onChanged: (String? type) {
                          setState(() => _typeFilter = type);
                          _entry?.markNeedsBuild();
                        },
                      ),
                      Divider(
                        height: 1,
                        color: (_edge != null
                                ? context.moduleBorderColor(_edge!)
                                : context.borderColor)
                            .withValues(alpha: 0.6),
                      ),
                      Flexible(
                        child: items.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.search_off,
                                      size: 18,
                                      color: context.mutedColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Eşleşen araç bulunamadı',
                                      style: TextStyle(color: context.mutedColor),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                shrinkWrap: true,
                                itemCount: items.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: (_edge != null
                                          ? context.moduleBorderColor(_edge!)
                                          : context.borderColor)
                                      .withValues(alpha: 0.6),
                                ),
                                itemBuilder: (BuildContext context, int i) {
                                  final Vehicle v = items[i];
                                  final bool isSelected = v.id == widget.selected?.id;
                                  return InkWell(
                                    onTap: () => _select(v),
                                    child: Container(
                                      color: isSelected
                                          ? accent.withValues(alpha: 0.08)
                                          : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          Icon(
                                            Icons.local_shipping_outlined,
                                            size: 24,
                                            color: isSelected
                                                ? accent
                                                : context.mutedColor,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  v.code,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected ? accent : null,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  v.typeLabel,
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
                                              color: accent,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: CompositedTransformTarget(
        link: _link,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (_) {
            _typing = true;
            setState(() {}); // temizle butonunun görünürlüğü için
            _entry?.markNeedsBuild();
          },
          onTap: _showOverlay,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Araç Seç',
            prefixIcon: const Icon(Icons.local_shipping_outlined, size: 24),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Temizle',
                    onPressed: _clear,
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
                color: _edge != null
                    ? context.moduleBorderColor(_edge!)
                    : context.borderColor,
                width: 2.5,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _edge != null
                    ? context.moduleBorderColor(_edge!)
                    : context.borderColor,
                width: 2.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
