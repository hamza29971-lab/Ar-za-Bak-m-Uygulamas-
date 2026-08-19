import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/auth_models.dart';
import '../services/service_locator.dart';

/// Uygulamanın tek merkezi durumu.
/// MQTT/backend eklenince bu sınıfın metotları servis çağrılarını tetikleyecek.
class AppState extends ChangeNotifier {
  AppState() {
    _vehicles = MockData.vehicles();
    _notifications = MockData.notifications();
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
    _user = session.user;
    await ServiceLocator.tokens.save(session);
    notifyListeners();
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

  // -------------------------------------------------------------- işlemler
  /// Lastik değişimi: [newSerialNo] verilirse takılan yeni lastiğin seri
  /// numarası kaydedilir, değişim ve kontrol tarihleri o ana çekilir.
  void changeTire(Vehicle vehicle, TireRecord record, {String? newSerialNo}) {
    final DateTime now = DateTime.now();
    final String serial = (newSerialNo ?? '').trim();
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
        'op': 'lastik_degisim',
        'tireId': record.tireId,
        'position': record.position,
        'serialNo': record.serialNo,
      },
    ));
    addNotification(
      NotificationItem(
        title: 'Lastik değişimi kaydedildi',
        message: '${vehicle.code} • ${record.position} (${record.tireId})'
            ' • Seri No: ${record.serialNo}',
        date: now,
        kind: NotificationKind.tire,
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
        'op': 'lastik_kontrol',
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
    record
      ..amount = amount
      ..lastOilDate = now;
    addActivity(
      OilRefillActivity(
        id: 'oil-${now.microsecondsSinceEpoch}',
        vehicleCode: vehicle.code,
        date: now,
        area: record.label,
        oilType: record.category.label,
        amount: amount,
      ),
    );
    addPending(PendingOperation(
      kind: PendingKind.oil,
      vehicleCode: vehicle.code,
      label: '${record.label} • ${amount.toStringAsFixed(1)} L'
          '${product.isEmpty ? '' : ' • $product'}',
      date: now,
      payload: <String, Object?>{
        'op': 'yag_takviye',
        'areaId': record.areaId,
        'oilType': record.oilType,
        'amount': amount,
        'product': product,
      },
    ));
    addNotification(
      NotificationItem(
        title: 'Yağ takviyesi kaydedildi',
        message: '${vehicle.code} • ${record.label}'
            ' • ${amount.toStringAsFixed(1)} L'
            '${product.isEmpty ? '' : ' • $product'}',
        date: now,
        kind: NotificationKind.oil,
      ),
    );
  }

  void checkOil(Vehicle vehicle, OilRecord record) {
    // Seviye kontrolü takviye tarihini değiştirmez, yalnızca kontrol tarihini
    // günceller (Servis Raporu bu tarihi kullanır).
    final DateTime now = DateTime.now();
    record.lastCheckDate = now;
    addPending(PendingOperation(
      kind: PendingKind.oil,
      vehicleCode: vehicle.code,
      label: '${record.label} kontrol edildi',
      date: now,
      payload: <String, Object?>{
        'op': 'yag_kontrol',
        'areaId': record.areaId,
        'oilType': record.oilType,
      },
    ));
    addNotification(
      NotificationItem(
        title: 'Kontroller tamamlandı',
        message: '${vehicle.code} • ${record.label}',
        date: now,
        kind: NotificationKind.oil,
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
      lastCheckDate: record.lastCheckDate,
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
    _pending.removeWhere((PendingOperation p) => p.kind == kind);
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
  const PendingOperation({
    required this.kind,
    required this.vehicleCode,
    required this.label,
    required this.date,
    required this.payload,
  });

  final PendingKind kind;
  final String vehicleCode;

  /// Kullanıcıya gösterilen kısa açıklama (ör. "Euclid-1-L01 değiştirildi").
  final String label;

  final DateTime date;

  /// MQTT yüküne eklenecek alanlar.
  final Map<String, Object?> payload;
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
