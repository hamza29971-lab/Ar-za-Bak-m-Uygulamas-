// lib/models/tire_change_model.dart

/// Her bir kontrol aksiyonunu kendi tarihi ile birlikte tutar
class TireActionRecord {
  final String action; // Örn: "Lastiklerin havası tamamlandı"
  final DateTime date; // Bu aksiyonun yapıldığı tarih/saat

  TireActionRecord({required this.action, required this.date});

  Map<String, dynamic> toJson() => {
        'action': action,
        'date': date.toIso8601String(),
      };

  factory TireActionRecord.fromJson(Map<String, dynamic> json) =>
      TireActionRecord(
        action: json['action'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}

class VehicleModel {
  final String id;
  final String name;
  final int tireCount;
  final String imagePath; // Yandan görünüm (orijinal)
  final String topDownImagePath; // Üstten görünüm (şasi)

  const VehicleModel({
    required this.id,
    required this.name,
    required this.tireCount,
    required this.imagePath,
    required this.topDownImagePath,
  });

  String get typeLabel {
    if (tireCount <= 4) return 'Yükleyici';
    if (tireCount <= 6) return 'Kaya Kamyonu';
    return 'Maden Kamyonu';
  }

  // Gerçek araç listesi
  static List<VehicleModel> demoVehicles() {
    return [
      // Euclıd 1-12 (6 Lastik)
      ...List.generate(12, (i) => VehicleModel(
        id: 'euclid_${i + 1}',
        name: 'Euclid-${i + 1}',
        tireCount: 6,
        imagePath: 'assets/images/yesil_arac.png',
        topDownImagePath: 'assets/images/truck_6_top_down.jpg',
      )),
      // Liugong 16-20 (10 Lastik)
      ...List.generate(5, (i) => VehicleModel(
        id: 'liugong_${i + 16}',
        name: 'Liugong-${i + 16}',
        tireCount: 10,
        imagePath: 'assets/images/green_truck.png',
        topDownImagePath: 'assets/images/truck_10_top_down.jpg',
      )),
      // XCMG 13-15 (10 Lastik)
      ...List.generate(3, (i) => VehicleModel(
        id: 'xcmg_${i + 13}',
        name: 'XCMG-${i + 13}',
        tireCount: 10,
        imagePath: 'assets/images/yesil_excavator.png',
        topDownImagePath: 'assets/images/truck_10_top_down.jpg',
      )),
      // Liugong 33-39 — Loder tipi (4 Lastik)
      ...List.generate(7, (i) => VehicleModel(
        id: 'liugong_${i + 33}',
        name: 'Liugong-${i + 33}',
        tireCount: 4,
        imagePath: 'assets/images/loader.png',
        topDownImagePath: 'assets/images/loader_top_down.jpg',
      )),
    ];
  }
}

class TireRecord {
  final int tireNumber;
  String serialNumber;
  DateTime lastChangedDate; // Seri No'nun son değiştirilme tarihi
  List<TireActionRecord> actionHistory; // Tüm kontrol aksiyonları (her biri kendi tarihiyle)
  bool isChanged; // Bu oturumda değiştirildi mi?

  TireRecord({
    required this.tireNumber,
    required this.serialNumber,
    required this.lastChangedDate,
    List<TireActionRecord>? actionHistory,
    this.isChanged = false,
  }) : actionHistory = actionHistory ?? [];

  /// Son kontrol aksiyonu (varsa)
  TireActionRecord? get lastAction =>
      actionHistory.isEmpty ? null : actionHistory.last;

  TireRecord copyWith({
    String? serialNumber,
    DateTime? lastChangedDate,
    List<TireActionRecord>? actionHistory,
    bool? isChanged,
  }) {
    return TireRecord(
      tireNumber: tireNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      lastChangedDate: lastChangedDate ?? this.lastChangedDate,
      actionHistory: actionHistory ?? List.from(this.actionHistory),
      isChanged: isChanged ?? this.isChanged,
    );
  }
}
