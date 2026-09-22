import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/auth_models.dart';
import '../services/vehicle_directory_service.dart';
import '../utils/formats.dart';
import '../services/service_locator.dart';

/// Uygulamanın tek merkezi durumu.
/// MQTT/backend eklenince bu sınıfın metotları servis çağrılarını tetikleyecek.
class AppState extends ChangeNotifier {
  AppState() {
    _vehicles = MockData.vehicles();
    _notifications = <NotificationItem>[];
    _activities = MockData.activities(_vehicles);
  }

  // ---------------------------------------------------------------- oturum
  UserProfile? _user;
  UserProfile? get user => _user;
  bool get isLoggedIn => _user != null;

  AuthSession? _session;
  AuthSession? get session => _session;

  /// Doğrulama başarılı olduğunda çağrılır: kullanıcı bilgisi ve anahtarlar
  /// saklanır. Anahtarların nerede tutulacağı [TokenStorage] ile belirlenir.
  Future<void> applySession(AuthSession session) async {
    _session = session;
    
    final prefs = await SharedPreferences.getInstance();
    final String key = 'local_user_profile_${session.user.email}';
    final String? localProfileJson = prefs.getString(key);
    
    UserProfile mergedUser = session.user;
    
    if (localProfileJson != null) {
      try {
        final Map<String, dynamic> localData = jsonDecode(localProfileJson);
        mergedUser = mergedUser.copyWith(
          phone: mergedUser.phone.trim().isEmpty ? localData['phone'] : null,
          registryNo: mergedUser.registryNo.trim().isEmpty ? localData['registryNo'] : null,
          machineCode: mergedUser.machineCode.trim().isEmpty ? localData['machineCode'] : null,
          machineType: mergedUser.machineType.trim().isEmpty ? localData['machineType'] : null,
        );
      } catch (_) {}
    }
    
    await prefs.setString(key, jsonEncode(mergedUser.toJson()));
    _user = mergedUser;
    
    await ServiceLocator.tokens.save(session);
    notifyListeners();

    // Giriş akışını bloklamaz; hata olursa vehicleUuidFor eşleşme bulamaz
    // ve loadVehicleDirectory'nin kendi debugPrint'i sebebi gösterir.
    unawaited(loadVehicleDirectory());
  }

  /// Eksik profil bilgilerini elle girildiğinde kaydetmek için kullanılır.
  Future<void> updateUserLocalData({
    String? phone,
    String? registryNo,
    String? machineCode,
    String? machineType,
  }) async {
    if (_user == null) return;
    
    _user = _user!.copyWith(
      phone: phone,
      registryNo: registryNo,
      machineCode: machineCode,
      machineType: machineType,
    );
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    final String key = 'local_user_profile_${_user!.email}';
    await prefs.setString(key, jsonEncode(_user!.toJson()));
  }

  /// Servis çağrısı yapmadan yerel oturum açar (testler ve demo için).
  void signIn({String? phone, String? email}) {
    final UserProfile base = MockData.user;
    _user = UserProfile(
      fullName: base.fullName,
      email: email?.isNotEmpty == true ? email! : base.email,
      phone: phone?.isNotEmpty == true ? phone! : base.phone,
      role: base.role,
      registryNo: base.registryNo,
      machineCode: base.machineCode,
      machineType: base.machineType,
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    _user = null;
    _session = null;
    _selectedVehicle = null;
    await ServiceLocator.tokens.clear();
    notifyListeners();
  }

  // ------------------------------------------------------------------ tema
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  static const String appVersion = '1.0.0';

  // ----------------------------------------------------------------- araç
  late List<Vehicle> _vehicles;
  List<Vehicle> get vehicles => List<Vehicle>.unmodifiable(_vehicles);

  Vehicle? _selectedVehicle;
  Vehicle? get selectedVehicle => _selectedVehicle;

  final Map<String, List<TireRecord>> _tires = <String, List<TireRecord>>{};
  final Map<String, List<OilRecord>> _oils = <String, List<OilRecord>>{};

  void selectVehicle(Vehicle? vehicle) {
    _selectedVehicle = vehicle;
    if (vehicle != null) {
      _tires.putIfAbsent(vehicle.id, () => MockData.tiresFor(vehicle));
      _oils.putIfAbsent(vehicle.id, () => MockData.oilsFor(vehicle));
    }
    notifyListeners();
  }

  /// Yazılan metne göre filtrelenmiş araç listesi.
  List<Vehicle> filterVehicles(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return vehicles;
    return _vehicles
        .where((Vehicle v) =>
            v.code.toLowerCase().contains(q) ||
            v.typeLabel.toLowerCase().contains(q) ||
            v.site.toLowerCase().contains(q))
        .toList();
  }

  List<TireRecord> tiresOf(Vehicle vehicle) =>
      _tires.putIfAbsent(vehicle.id, () => MockData.tiresFor(vehicle));

  List<OilRecord> oilsOf(Vehicle vehicle) =>
      _oils.putIfAbsent(vehicle.id, () => MockData.oilsFor(vehicle));

  // ------------------------------------------------------ araç UUID dizini
  final VehicleDirectoryService _vehicleDirectoryService = VehicleDirectoryService();
  Map<String, String> _vehicleUuidByCode = <String, String>{};

  /// `Vehicle.code`'u mining-be'deki araç UUID'sine çevirir. Dizin henüz
  /// yüklenmemişse ya da eşleşme bulunamazsa `null` döner.
  String? vehicleUuidFor(String? vehicleCode) {
    if (vehicleCode == null || vehicleCode.trim().isEmpty) return null;
    final String? key = _canonicalKey(vehicleCode);
    return key == null ? null : _vehicleUuidByCode[key];
  }

  /// Sunucudaki isimlendirme yerel kodlardan tamamen farklı:
  /// `05-01-IM-KK-EUCLID.02` ↔ `Euclid-2`, `05-01-IM-KK-HTC.EUC.09` ↔
  /// `Euclid-9`, `05-01-IM-KK-XCMG.E.13E` ↔ `XCMG-13`. Ortak nokta marka ve
  /// sıra numarası olduğu için iki taraf da `MARKA#NUMARA` biçimine indirgenip
  /// öyle eşleştirilir. Marka bilinmiyorsa eşleşme denenmez; yalnızca
  /// numarası tutan yabancı bir araca bağlanmak, eşleşmemekten daha kötüdür.
  static const Map<String, String> _brandAliases = <String, String>{
    'EUCLID': 'EUCLID',
    'EUC': 'EUCLID',
    // Sunucuda Euclid-11/12'nin karşılığı "ARK 11"/"ARK 12" olarak kayıtlı.
    'ARK': 'EUCLID',
    'XCMG': 'XCMG',
    'LIUGONG': 'LIUGONG',
    'LIUG': 'LIUGONG',
    // Sunucudaki bazı kayıtlarda harfler yer değiştirmiş yazılmış.
    'LUIGONG': 'LIUGONG',
    'HITACHI': 'HITACHI',
    'HITC': 'HITACHI',
    'HITCEX': 'HITACHI',
    'SANY': 'SANY',
    'SY': 'SANY',
    'KOMATSU': 'KOMATSU',
    'KOMT': 'KOMATSU',
  };

  static String? _canonicalKey(String label) {
    final List<String> tokens = label
        .toUpperCase()
        .split(RegExp(r'[^A-Z0-9]+'))
        .where((String t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;

    String? brand;
    for (final String token in tokens) {
      final String? mapped = _brandAliases[token];
      if (mapped != null) {
        brand = mapped;
        continue;
      }
      // Bitişik marka+numara token'ları ("HITCEX1200"): bilinen bir marka
      // önekiyle başlayıp devamı tamamen rakamsa, yine marka sayılır.
      for (final MapEntry<String, String> alias in _brandAliases.entries) {
        if (token.length > alias.key.length &&
            token.startsWith(alias.key) &&
            RegExp(r'^[0-9]+$').hasMatch(token.substring(alias.key.length))) {
          brand = alias.value;
          break;
        }
      }
    }
    if (brand == null) return null;

    // Sondaki numara: `02` → 2, `13E` → 13.
    final String digits = tokens.last.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return '$brand#${int.parse(digits)}';
  }

  /// Testler için: dizini ağdan çekmeden UUID önbelleğini doldurur.
  @visibleForTesting
  void seedVehicleDirectory(Map<String, String> uuidByLabel) {
    _vehicleUuidByCode = <String, String>{
      for (final MapEntry<String, String> e in uuidByLabel.entries)
        if (_canonicalKey(e.key) case final String key) key: e.value,
    };
  }

  /// mining-be'den araç listesini çekip yerel filoyla eşleştirir.
  /// `applySession` içinde girişten hemen sonra tetiklenir.
  Future<void> loadVehicleDirectory() async {
    final String? accessToken = await ServiceLocator.tokens.readAccessToken();
    final List<VehicleDirectoryEntry> entries =
        await _vehicleDirectoryService.fetchAll(accessToken: accessToken);
    if (entries.isEmpty) return;

    final Map<String, String> byKey = <String, String>{};
    for (final VehicleDirectoryEntry entry in entries) {
      final String? key = _canonicalKey(entry.label);
      if (key != null) byKey[key] = entry.id;
    }
    _vehicleUuidByCode = byKey;

    for (final Vehicle vehicle in _vehicles) {
      final String? key = _canonicalKey(vehicle.code);
      if (key == null || !byKey.containsKey(key)) {
        debugPrint('[FleetUUID] eşleşmedi: ${vehicle.code}');
      }
    }
    debugPrint('[FleetUUID] ${byKey.length} araç eşleştirildi');
  }

  // -------------------------------------------------------------- işlemler
  /// Lastik değişimi: [newSerialNo] verilirse takılan yeni lastiğin seri
  /// numarası kaydedilir, değişim ve kontrol tarihleri o ana çekilir.
  void changeTire(Vehicle vehicle, TireRecord record, {String? newSerialNo}) {
    final DateTime now = DateTime.now();
    final String serial = (newSerialNo ?? '').trim();
    // Sökülen lastiğin seri numarası da gönderildiği için değişiklik
    // uygulanmadan önce okunur.
    final String previousSerialNo = record.serialNo;
    if (serial.isNotEmpty) record.serialNo = serial;
    record
      ..lastChangeDate = now
      ..lastCheckDate = now;
    _recordTireChange(vehicle, record, now);
    addPending(PendingOperation(
      kind: PendingKind.tire,
      vehicleCode: vehicle.code,
      label: '${record.tireId} değiştirildi (${record.serialNo})',
      date: now,
      payload: <String, Object?>{
        'op': 'degisim',
        'tireId': record.tireId,
        'position': record.position,
        'serialNo': record.serialNo,
        'previousSerialNo': previousSerialNo,
      },
    ));
    addNotification(
      NotificationItem(
        title: 'Lastik değişimi kaydedildi',
        message: '${vehicle.code} • ${record.position} (${record.tireId})'
            ' • Seri No: ${record.serialNo}',
        date: now,
        kind: NotificationKind.tire,
        vehicleCode: vehicle.code,
        details: <String, String>{
          'İşlem': 'Lastik değişimi',
          'Lastik': record.tireId,
          'Konum': record.position,
          'Yeni seri numarası': record.serialNo,
          'Değişim tarihi': formatDateTime(now),
        },
      ),
    );
  }

  /// Lastik kontrolü: kontrol formunda işaretlenen maddeler [items] ile gelir.
  void checkTire(
    Vehicle vehicle,
    TireRecord record, {
    List<String> items = const <String>[],
    String note = '',
  }) {
    final DateTime now = DateTime.now();
    record.lastCheckDate = now;
    final String detail = items.isEmpty ? '' : ' • ${items.join(', ')}';
    final String noteText = note.trim().isEmpty ? '' : ' • Not: ${note.trim()}';
    addPending(PendingOperation(
      kind: PendingKind.tire,
      vehicleCode: vehicle.code,
      label: '${record.tireId} kontrol edildi',
      date: now,
      payload: <String, Object?>{
        'op': 'kontrol',
        'tireId': record.tireId,
        'position': record.position,
        'items': items,
        'note': note.trim(),
      },
    ));
    addNotification(
      NotificationItem(
        title: 'Lastik kontrolü tamamlandı',
        message: '${vehicle.code} • ${record.position} (${record.tireId})'
            '$detail$noteText',
        date: now,
        kind: NotificationKind.tire,
        vehicleCode: vehicle.code,
        details: <String, String>{
          'İşlem': 'Lastik kontrolü',
          'Lastik': record.tireId,
          'Konum': record.position,
          'Kontrol edilenler': items.isEmpty ? '-' : items.join(', '),
          'Not': note.trim(),
          'Kontrol tarihi': formatDateTime(now),
        },
      ),
    );
  }

  /// [product] kullanılan yağ / gres ürünüdür;
  /// takviye penceresinde seçilir, rapora ve MQTT yüküne yazılır.
  void refillOil(
    Vehicle vehicle,
    OilRecord record,
    double amount, {
    String product = '',
  }) {
    final DateTime now = DateTime.now();
    // Takviye gönderilmeden önce düzeltilebilsin diye kaydın önceki hâli
    // saklanır; bkz. [cancelOilRefill].
    final double previousAmount = record.amount;
    final DateTime? previousOilDate = record.lastOilDate;
    final String previousProduct = record.lastProduct;
    record
      ..amount = amount
      ..lastOilDate = now
      ..lastProduct = product;
    final String activityId = 'oil-${now.microsecondsSinceEpoch}';
    addActivity(
      OilRefillActivity(
        id: activityId,
        vehicleCode: vehicle.code,
        date: now,
        area: record.label,
        oilType: record.category.label,
        amount: amount,
      ),
    );
    final PendingOperation pending = PendingOperation(
      kind: PendingKind.oil,
      vehicleCode: vehicle.code,
      label: _refillLabel(record, amount, product),
      date: now,
      payload: <String, Object?>{
        // Manuel yağlama / yağ takviyesi ayrımını `category` (panelde
        // `subtitle`) taşır; `op` yalnızca işlemin türünü söyler.
        'op': 'takviye',
        'category': record.category.pluralLabel,
        'oilType': record.oilType,
        'amount': amount,
        'product': product,
      },
    );
    _pendingRefills[pending.id] = _PendingRefill(
      record: record,
      activityId: activityId,
      previousAmount: previousAmount,
      previousOilDate: previousOilDate,
      previousProduct: previousProduct,
    );
    addPending(pending);
    addNotification(
      NotificationItem(
        title: 'Yağ takviyesi kaydedildi',
        message: '${vehicle.code} • ${record.label}'
            ' • ${amount.toStringAsFixed(1)} L'
            '${product.isEmpty ? '' : ' • $product'}',
        date: now,
        kind: NotificationKind.oil,
        vehicleCode: vehicle.code,
        details: <String, String>{
          'İşlem': 'Yağ takviyesi',
          'Takviye yapılan bölge': record.label,
          'Yağ türü': record.category.label,
          'Kullanılan ürün': product,
          'Takviye miktarı': '${amount.toStringAsFixed(1)} L',
          'Önceki miktar': '${previousAmount.toStringAsFixed(1)} L',
          'Takviye tarihi': formatDateTime(now),
        },
      ),
    );
  }

  // ------------------------------------------- bekleyen takviyenin düzeltilmesi
  /// Gönderilmeyi bekleyen takviyelerin bağlamı (pending id -> kayıt + önceki hâl).
  final Map<String, _PendingRefill> _pendingRefills = <String, _PendingRefill>{};

  /// Gönderilmeyi bekleyen seviye kontrollerinin bağlamı
  /// (pending id -> kayıt + kontrolden önceki tarih).
  final Map<String, _PendingCheck> _pendingChecks = <String, _PendingCheck>{};

  static String _refillLabel(OilRecord record, double amount, String product) =>
      '${record.label} • ${amount.toStringAsFixed(1)} L'
      '${product.isEmpty ? '' : ' • $product'}';

  /// [record] için gönderilmeyi bekleyen takviye; yoksa `null`.
  /// Ekran, bu kayıt varsa satırda "Takviye Yap" yerine "Düzenle" gösterir.
  PendingOperation? pendingRefillFor(Vehicle vehicle, OilRecord record) {
    for (final PendingOperation p in _pending) {
      if (p.kind != PendingKind.oil || p.vehicleCode != vehicle.code) continue;
      if (identical(_pendingRefills[p.id]?.record, record)) return p;
    }
    return null;
  }

  /// Bekleyen bir takviyenin miktarını / ürününü değiştirir.
  /// Kayıt, işlem geçmişi ve MQTT yükü birlikte güncellenir.
  void updateOilRefill(
    PendingOperation pending,
    double amount, {
    String product = '',
  }) {
    final _PendingRefill? context = _pendingRefills[pending.id];
    final int index =
        _pending.indexWhere((PendingOperation p) => p.id == pending.id);
    if (context == null || index < 0) return;

    final DateTime now = DateTime.now();
    context.record
      ..amount = amount
      ..lastOilDate = now
      ..lastProduct = product;
    for (final ActivityRecord activity in _activities) {
      if (activity.id == context.activityId && activity is OilRefillActivity) {
        activity
          ..amount = amount
          ..date = now;
        break;
      }
    }
    _pending[index] = pending.copyWith(
      label: _refillLabel(context.record, amount, product),
      date: now,
      payload: <String, Object?>{
        ...pending.payload,
        'amount': amount,
        'product': product,
      },
    );
    notifyListeners();
  }

  /// Bekleyen takviyeyi tamamen geri alır: kuyruktan ve işlem geçmişinden
  /// silinir, kayıt takviyeden önceki hâline döner.
  void cancelOilRefill(PendingOperation pending) {
    final _PendingRefill? context = _pendingRefills.remove(pending.id);
    _pending.removeWhere((PendingOperation p) => p.id == pending.id);
    if (context != null) {
      context.record
        ..amount = context.previousAmount
        ..lastOilDate = context.previousOilDate
        ..lastProduct = context.previousProduct;
      _activities
          .removeWhere((ActivityRecord a) => a.id == context.activityId);
    }
    notifyListeners();
  }

  /// Yağ ekranında yapılıp henüz gönderilmemiş tüm işlemleri geri alır:
  /// takviyeler ve kontroller kuyruktan düşer, kayıtlar işlem öncesi hâline
  /// döner ve takviyelerin işlem geçmişi satırları silinir. Bildirim geçmişi
  /// [cancelOilRefill] ile aynı şekilde korunur.
  ///
  /// Geri alınan işlem sayısını döndürür.
  int discardPendingOil() {
    final List<PendingOperation> oil = _pending
        .where((PendingOperation p) => p.kind == PendingKind.oil)
        .toList();
    for (final PendingOperation p in oil) {
      final _PendingRefill? refill = _pendingRefills.remove(p.id);
      if (refill != null) {
        refill.record
          ..amount = refill.previousAmount
          ..lastOilDate = refill.previousOilDate
          ..lastProduct = refill.previousProduct;
        _activities
            .removeWhere((ActivityRecord a) => a.id == refill.activityId);
      }
      final _PendingCheck? check = _pendingChecks.remove(p.id);
      if (check != null) {
        check.record.lastCheckDate = check.previousCheckDate;
      }
    }
    _pending.removeWhere((PendingOperation p) => p.kind == PendingKind.oil);
    notifyListeners();
    return oil.length;
  }

  /// Lastik ekranında yapılıp gönderilmeyen işlemleri iptal eder: işlemler
  /// kuyruktan düşer ve bunlarla eklenen işlem geçmişi satırları silinir.
  /// Lastik kayıtlarının kendisi `TireChangeProvider.discardChanges` ile
  /// eski hâline döner. Bildirim geçmişi [discardPendingOil] ile aynı
  /// mantıkla korunur.
  ///
  /// Geri alınan işlem sayısını döndürür.
  int discardPendingTire() {
    final List<PendingOperation> tire = _pending
        .where((PendingOperation p) => p.kind == PendingKind.tire)
        .toList();
    for (final PendingOperation p in tire) {
      final String? activityId = p.activityId;
      if (activityId == null) continue;
      _activities.removeWhere((ActivityRecord a) => a.id == activityId);
    }
    _pending.removeWhere((PendingOperation p) => p.kind == PendingKind.tire);
    notifyListeners();
    return tire.length;
  }

  void checkOil(Vehicle vehicle, OilRecord record) {
    // Seviye kontrolü takviye tarihini değiştirmez, yalnızca kontrol tarihini
    // günceller (Servis Raporu bu tarihi kullanır).
    final DateTime now = DateTime.now();
    // Kontrol gönderilmeden iptal edilebilsin diye önceki tarih saklanır;
    // bkz. [discardPendingOil].
    final DateTime? previousCheckDate = record.lastCheckDate;
    record.lastCheckDate = now;
    final PendingOperation pending = PendingOperation(
      kind: PendingKind.oil,
      vehicleCode: vehicle.code,
      label: '${record.label} kontrol edildi',
      date: now,
      payload: <String, Object?>{
        'op': 'kontrol',
        'category': record.category.pluralLabel,
        'oilType': record.oilType,
        // Kontrolde yeni bir miktar/ürün girilmez; kayıttaki son takviye
        // bilgisi bildirilir. Hiç takviye yapılmamışsa gönderilmez.
        if (record.amount > 0) 'amount': record.amount,
        if (record.lastProduct.trim().isNotEmpty)
          'product': record.lastProduct.trim(),
      },
    );
    _pendingChecks[pending.id] = _PendingCheck(
      record: record,
      previousCheckDate: previousCheckDate,
    );
    addPending(pending);
    addNotification(
      NotificationItem(
        title: 'Kontroller tamamlandı',
        message: '${vehicle.code} • ${record.label}',
        date: now,
        kind: NotificationKind.oil,
        vehicleCode: vehicle.code,
        details: <String, String>{
          'İşlem': 'Yağ seviyesi kontrolü',
          'Kontrol edilen bölge': record.label,
          'Yağ türü': record.category.label,
          'Kontrol tarihi': formatDateTime(now),
        },
      ),
    );
  }

  // ---------------------------------------------------------- işlem geçmişi
  late List<ActivityRecord> _activities;
  List<ActivityRecord> get activities => List<ActivityRecord>.unmodifiable(_activities);

  /// Anasayfadaki listede gösterilecek son işlemler.
  List<ActivityRecord> recentActivities([int limit = 10]) =>
      _activities.take(limit).toList();

  /// Aynı araçta bu süre içinde yapılan lastik değişimleri tek kayıtta toplanır;
  /// böylece "4 lastik değiştirildi" tek bir işlem olarak görünür.
  static const Duration tireGroupWindow = Duration(minutes: 30);

  void addActivity(ActivityRecord activity) {
    _activities.insert(0, activity);
    notifyListeners();
  }

  void _recordTireChange(Vehicle vehicle, TireRecord record, DateTime now) {
    final TireChangeDetail detail = TireChangeDetail(
      tireId: record.tireId,
      serialNo: record.serialNo,
      position: record.position,
      changedAt: now,
      lastCheckDate: record.lastCheckDate ?? now,
    );

    // Liste yeniden eskiye sıralı; ilk eşleşen kayıt en günceli.
    for (final ActivityRecord activity in _activities) {
      if (activity is TireChangeActivity &&
          activity.vehicleCode == vehicle.code &&
          now.difference(activity.date) <= tireGroupWindow) {
        activity
          ..tires.add(detail)
          ..date = now;
        _activities
          ..remove(activity)
          ..insert(0, activity);
        notifyListeners();
        return;
      }
    }

    addActivity(
      TireChangeActivity(
        id: 'tire-${now.microsecondsSinceEpoch}',
        vehicleCode: vehicle.code,
        date: now,
        tires: <TireChangeDetail>[detail],
      ),
    );
  }

  // ------------------------------------------------- gönderilmeyi bekleyenler
  final List<PendingOperation> _pending = <PendingOperation>[];

  /// Belirtilen ekranda yapılıp henüz gönderilmemiş işlemler (eskiden yeniye).
  List<PendingOperation> pendingOf(PendingKind kind) => List<PendingOperation>
      .unmodifiable(_pending.where((PendingOperation p) => p.kind == kind));

  int pendingCount(PendingKind kind) =>
      _pending.where((PendingOperation p) => p.kind == kind).length;

  void addPending(PendingOperation operation) {
    _pending.add(operation);
    notifyListeners();
  }

  /// Gönderim başarılı olunca kuyruk boşaltılır.
  void clearPending(PendingKind kind) {
    _pending.removeWhere((PendingOperation p) {
      if (p.kind != kind) return false;
      // Gönderilen işlem artık düzenlenemez; geri alma bağlamı da düşer.
      _pendingRefills.remove(p.id);
      _pendingChecks.remove(p.id);
      return true;
    });
    notifyListeners();
  }

  // ------------------------------------------------------------ bildirimler
  late List<NotificationItem> _notifications;
  List<NotificationItem> get notifications =>
      List<NotificationItem>.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((NotificationItem n) => !n.read).length;

  void addNotification(NotificationItem item) {
    _notifications.insert(0, item);
    notifyListeners();
  }

  /// Tek bir kaydı okundu işaretler; geçmiş penceresinde kayda tıklanınca.
  void markRead(NotificationItem item) {
    if (item.read) return;
    item.read = true;
    notifyListeners();
  }

  void markAllRead() {
    for (final NotificationItem n in _notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void clearNotifications() {
    _notifications = <NotificationItem>[];
    notifyListeners();
  }
}

/// Bekleyen işlemlerin hangi ekrana ait olduğu.
enum PendingKind {
  tire('lastik', 'nimo/bakim/lastik'),
  oil('yag', 'nimo/bakim/yag');

  const PendingKind(this.label, this.topic);

  /// Yükteki grup adı.
  final String label;

  /// İşlemlerin gönderileceği MQTT konusu.
  final String topic;
}

/// Yapılmış ama henüz gönderilmemiş bir işlem.
///
/// Lastik / Yağ ekranlarındaki "Gönder" butonu bu kuyruğu boşaltır; böylece
/// saha çalışanı birkaç işlemi arka arkaya yapıp tek seferde gönderebilir.
@immutable
class PendingOperation {
  PendingOperation({
    required this.kind,
    required this.vehicleCode,
    required this.label,
    required this.date,
    required this.payload,
    this.activityId,
  }) : id = 'pnd-${_sequence++}';

  /// [copyWith] için; kimliği korur.
  const PendingOperation._({
    required this.id,
    required this.kind,
    required this.vehicleCode,
    required this.label,
    required this.date,
    required this.payload,
    this.activityId,
  });

  static int _sequence = 0;

  /// Kuyruktaki kaydı gönderilmeden önce bulup güncellemeye yarar.
  final String id;

  final PendingKind kind;
  final String vehicleCode;

  /// Kullanıcıya gösterilen kısa açıklama (ör. "Euclid-1-L01 değiştirildi").
  final String label;

  final DateTime date;

  /// MQTT yüküne eklenecek alanlar.
  final Map<String, Object?> payload;

  /// Bu işlemle birlikte eklenen işlem geçmişi satırının kimliği; işlem
  /// gönderilmeden iptal edilirse o satır da silinir.
  final String? activityId;

  PendingOperation copyWith({
    String? label,
    DateTime? date,
    Map<String, Object?>? payload,
  }) {
    return PendingOperation._(
      id: id,
      kind: kind,
      vehicleCode: vehicleCode,
      label: label ?? this.label,
      date: date ?? this.date,
      payload: payload ?? this.payload,
      activityId: activityId,
    );
  }
}

/// Bekleyen bir yağ takviyesinin, gönderilmeden önce düzeltilebilmesi için
/// gereken bağlamı: hangi kayda yapıldığı, hangi işlem geçmişi satırını
/// oluşturduğu ve kaydın takviyeden önceki hâli.
class _PendingRefill {
  const _PendingRefill({
    required this.record,
    required this.activityId,
    required this.previousAmount,
    required this.previousOilDate,
    required this.previousProduct,
  });

  final OilRecord record;
  final String activityId;
  final double previousAmount;
  final DateTime? previousOilDate;

  /// Takviyeden önceki ürün; iptal edilirse kayda geri yazılır.
  final String previousProduct;
}

/// Bekleyen bir seviye kontrolünün iptal edilebilmesi için gereken bağlam:
/// hangi kayda yapıldığı ve kaydın kontrolden önceki tarihi.
class _PendingCheck {
  const _PendingCheck({required this.record, required this.previousCheckDate});

  final OilRecord record;
  final DateTime? previousCheckDate;
}

/// [AppState]'i widget ağacına dağıtan kapsayıcı.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final AppScope? scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope bulunamadı');
    return scope!.notifier!;
  }

  /// Dinlemeden erişim (olay tetikleyicileri için).
  static AppState read(BuildContext context) {
    final AppScope? scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope bulunamadı');
    return scope!.notifier!;
  }
}
