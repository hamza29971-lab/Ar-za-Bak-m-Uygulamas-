// lib/models/tire_change_model.dart

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

  // Gerçek araç listesi
  static List<VehicleModel> demoVehicles() {
    return [
      // Lodel 1 (4 Lastik)
      const VehicleModel(
        id: 'lodel_1',
        name: 'Lodel-1',
        tireCount: 4,
        imagePath: 'assets/images/loader.png',
        topDownImagePath: 'assets/images/loader_top_down.jpg',
      ),
      // Euclıd 1-12 (6 Lastik)
      ...List.generate(12, (i) => VehicleModel(
        id: 'euclid_${i + 1}',
        name: 'Euclıd-${i + 1}',
        tireCount: 6,
        imagePath: 'assets/images/euclid_truck.png',
        topDownImagePath: 'assets/images/truck_6_top_down.jpg',
      )),
      // Lıugong 16-20 (10 Lastik)
      ...List.generate(5, (i) => VehicleModel(
        id: 'liugong_${i + 16}',
        name: 'Lıugong-${i + 16}',
        tireCount: 10,
        imagePath: 'assets/images/green_truck.png',
        topDownImagePath: 'assets/images/truck_10_top_down.jpg',
      )),
      // XCMG 13-15 (10 Lastik)
      ...List.generate(3, (i) => VehicleModel(
        id: 'xcmg_${i + 13}',
        name: 'XCMG-${i + 13}',
        tireCount: 10,
        imagePath: 'assets/images/xcmg_truck.png',
        topDownImagePath: 'assets/images/truck_10_top_down.jpg',
      )),
    ];
  }
}

class TireRecord {
  final int tireNumber;
  String serialNumber;
  DateTime lastChangedDate;
  String? lastAction; // Örn: "Lastiklerin havası tamamlandı"
  bool isChanged; // bu oturumda değiştirildi mi?

  TireRecord({
    required this.tireNumber,
    required this.serialNumber,
    required this.lastChangedDate,
    this.lastAction,
    this.isChanged = false,
  });

  TireRecord copyWith({
    String? serialNumber,
    DateTime? lastChangedDate,
    String? lastAction,
    bool? isChanged,
  }) {
    return TireRecord(
      tireNumber: tireNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      lastChangedDate: lastChangedDate ?? this.lastChangedDate,
      lastAction: lastAction ?? this.lastAction,
      isChanged: isChanged ?? this.isChanged,
    );
  }
}
