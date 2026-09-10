// lib/providers/tire_change_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tire_change_model.dart';
import '../state/app_state.dart';

class TireChangeProvider extends ChangeNotifier {
  // Tüm araç listesi
  final List<VehicleModel> vehicles = VehicleModel.demoVehicles();

  // Seçili araç
  VehicleModel? _selectedVehicle;
  VehicleModel? get selectedVehicle => _selectedVehicle;

  void clearSelectedVehicle() {
    _selectedVehicle = null;
    _tireRecords = [];
    _editingTireNumber = null;
    notifyListeners();
  }

  // Seçili araca ait lastik kayıtları
  List<TireRecord> _tireRecords = [];
  List<TireRecord> get tireRecords => List.unmodifiable(_tireRecords);

  // Hangi satır "değiştirme modunda" — null ise hiçbiri
  int? _editingTireNumber;
  int? get editingTireNumber => _editingTireNumber;

  // Gönderme durumu (demo için simüle edilecek)
  bool _isSending = false;
  bool get isSending => _isSending;

  bool _sendSuccess = false;
  bool get sendSuccess => _sendSuccess;

  // Arama sorgusu
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Filtrelenmiş araç listesi
  List<VehicleModel> get filteredVehicles {
    if (_searchQuery.isEmpty) return vehicles;
    final q = _searchQuery.toLowerCase();
    return vehicles.where((v) => v.name.toLowerCase().contains(q)).toList();
  }

  TireChangeProvider() {
    // Başlangıçta hiçbir araç seçilmeyecek (Yağ ekranı ile aynı mantık)
  }

  /// Arama sorgusunu güncelle
  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Arama sorgusunu temizle
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Araç seçimi
  void selectVehicle(VehicleModel vehicle) {
    _selectedVehicle = vehicle;
    _editingTireNumber = null;
    _loadTireRecords(vehicle);
    notifyListeners();
  }

  /// SharedPreferences'tan lastik kayıtlarını yükle
  Future<void> _loadTireRecords(VehicleModel vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tire_records_v2_${vehicle.id}'; // v2: yeni format
    final jsonStr = prefs.getString(key);

    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        _tireRecords = jsonList.map((item) {
          // actionHistory listesini yükle
          final List<TireActionRecord> history = [];
          if (item['actionHistory'] != null) {
            for (final a in item['actionHistory'] as List) {
              history.add(TireActionRecord.fromJson(Map<String, dynamic>.from(a)));
            }
          }
          return TireRecord(
            tireNumber: item['tireNumber'],
            serialNumber: item['serialNumber'],
            lastChangedDate: DateTime.parse(item['lastChangedDate']),
            actionHistory: history,
          );
        }).toList();
      } catch (_) {
        _tireRecords = _generateDefaultRecords(vehicle.tireCount);
      }
    } else {
      _tireRecords = _generateDefaultRecords(vehicle.tireCount);
    }

    notifyListeners();
  }

  /// Varsayılan lastik kayıtları oluştur
  List<TireRecord> _generateDefaultRecords(int count) {
    return List.generate(count, (i) {
      return TireRecord(
        tireNumber: i + 1,
        serialNumber: 'SN-904${(i + 1) * 11}',
        lastChangedDate: DateTime.now(),
        actionHistory: [],
      );
    });
  }

  /// Gönderilmemiş değişikliklerin öncesindeki hâlleri (lastik no -> kayıt).
  /// Aynı lastik birkaç kez düzenlense de ilk hâli korunur; "İptal Et" bunları
  /// geri yükler, gönderim tamamlanınca [resetChangedTires] ile düşerler.
  final Map<int, TireRecord> _undoSnapshots = {};

  /// Değişiklikten önce kaydın kopyası alınır (aynı lastik için yalnızca ilki).
  void _snapshot(int tireNumber) {
    if (_undoSnapshots.containsKey(tireNumber)) return;
    final idx = _tireRecords.indexWhere((r) => r.tireNumber == tireNumber);
    if (idx < 0) return;
    final r = _tireRecords[idx];
    _undoSnapshots[tireNumber] = TireRecord(
      tireNumber: r.tireNumber,
      serialNumber: r.serialNumber,
      lastChangedDate: r.lastChangedDate,
      actionHistory: List<TireActionRecord>.from(r.actionHistory),
      isChanged: r.isChanged,
    );
  }

  /// Gönderilmeden iptal edilen işlemler: kayıtlar değişiklik öncesi hâline
  /// döner. Geri alınan lastik sayısını döndürür.
  Future<int> discardChanges() async {
    if (_undoSnapshots.isEmpty) return 0;
    final int count = _undoSnapshots.length;
    for (final entry in _undoSnapshots.entries) {
      final idx = _tireRecords.indexWhere((r) => r.tireNumber == entry.key);
      if (idx >= 0) _tireRecords[idx] = entry.value;
    }
    _undoSnapshots.clear();
    _editingTireNumber = null;
    await _saveTireRecords();
    notifyListeners();
    return count;
  }

  /// Bir lastiği "düzenleme moduna" al
  void startEditing(int tireNumber) {
    _editingTireNumber = tireNumber;
    notifyListeners();
  }

  /// Düzenlemeyi iptal et
  void cancelEditing() {
    _editingTireNumber = null;
    notifyListeners();
  }

  /// Yeni seri numarası ile lastiği güncelle
  Future<void> confirmChange(int tireNumber, String newSerial) async {
    if (newSerial.trim().isEmpty) {
      _editingTireNumber = null;
      notifyListeners();
      return;
    }

    _snapshot(tireNumber);
    final idx = _tireRecords.indexWhere((r) => r.tireNumber == tireNumber);
    if (idx >= 0) {
      _tireRecords[idx] = _tireRecords[idx].copyWith(
        serialNumber: newSerial.trim(),
        lastChangedDate: DateTime.now(),
        isChanged: true,
      );
    }
    _editingTireNumber = null;
    await _saveTireRecords();
    notifyListeners();
  }

  /// Tıklanan lastik için aksiyonları upsert et:
  /// - Aynı aksiyon daha önce eklenmişse tarihi günceller
  /// - Yoksa yeni kayıt olarak ekler
  Future<void> setTireActions(int tireNumber, List<String> actions) async {
    if (actions.isEmpty) return;
    _snapshot(tireNumber);
    final idx = _tireRecords.indexWhere((r) => r.tireNumber == tireNumber);
    if (idx >= 0) {
      final now = DateTime.now(); // Aynı anda işaretlenenler aynı zamanı paylaşır
      final newHistory = List<TireActionRecord>.from(_tireRecords[idx].actionHistory);
      for (final action in actions) {
        final existingIdx = newHistory.indexWhere((a) => a.action == action);
        if (existingIdx >= 0) {
          // Aynı aksiyon zaten var — sadece tarihini güncelle
          newHistory[existingIdx] = TireActionRecord(action: action, date: now);
        } else {
          // Yeni aksiyon — listeye ekle
          newHistory.add(TireActionRecord(action: action, date: now));
        }
      }
      _tireRecords[idx] = _tireRecords[idx].copyWith(
        actionHistory: newHistory,
        isChanged: true,
      );
      await _saveTireRecords();
      notifyListeners();
    }
  }

  /// Kayıtları SharedPreferences'a kaydet (v2 formatı)
  Future<void> _saveTireRecords() async {
    if (_selectedVehicle == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'tire_records_v2_${_selectedVehicle!.id}';
    final jsonList = _tireRecords
        .map((r) => {
              'tireNumber': r.tireNumber,
              'serialNumber': r.serialNumber,
              'lastChangedDate': r.lastChangedDate.toIso8601String(),
              'actionHistory': r.actionHistory.map((a) => a.toJson()).toList(),
            })
        .toList();
    await prefs.setString(key, jsonEncode(jsonList));
  }

  /// Gönder — Demo: sunucuya gönderme simülasyonu ve AppState'e kaydetme
  Future<void> sendReport(AppState state) async {
    _isSending = true;
    _sendSuccess = false;
    notifyListeners();

    // Anasayfa Son İşlemler için değişen lastikleri ayır
    final changedTires = _tireRecords.where((r) => r.isChanged).toList();
    final vehicleName = _selectedVehicle?.name;

    // Demo: 1.5 saniye bekle (gerçekte HTTP isteği yapılacak)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Değişen lastik işlemlerini AppState'e ekle
    if (vehicleName != null && changedTires.isNotEmpty) {
      final vehicle = state.vehicles.where((v) => v.code == vehicleName).firstOrNull;
      if (vehicle != null) {
        for (final tireModel in changedTires) {
          final tireId = '${vehicle.code}-L${tireModel.tireNumber.toString().padLeft(2, '0')}';
          final tireRecord = state.tiresOf(vehicle)
              .where((t) => t.tireId == tireId)
              .firstOrNull;
          if (tireRecord != null) {
            // Eğer yeni bir lastik takıldı ise seri no parametresi verilebilir
            state.changeTire(vehicle, tireRecord, newSerialNo: tireModel.serialNumber);
          }
        }
      }
    }

    // Gönderim sonrası "isChanged" bayraklarını sıfırla
    _tireRecords = _tireRecords.map((r) => r.copyWith(isChanged: false)).toList();

    _isSending = false;
    _sendSuccess = true;
    notifyListeners();

    // 3 saniye sonra başarı mesajını gizle
    await Future.delayed(const Duration(seconds: 3));
    _sendSuccess = false;
    notifyListeners();
  }

  /// Gönderim sonrasında seri numaralarını '---' haline getir
  Future<void> resetChangedTires() async {
    // Gönderilen işlemler artık iptal edilemez.
    _undoSnapshots.clear();
    _tireRecords = _tireRecords.map((r) => r.copyWith(
      isChanged: false,
    )).toList();
    await _saveTireRecords();
    notifyListeners();
  }
}
