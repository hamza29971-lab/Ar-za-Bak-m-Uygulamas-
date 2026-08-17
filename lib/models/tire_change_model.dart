// lib/models/tire_change_model.dart

class VehicleModel {
  final String id;
  final String name;
  final int tireCount;
  final String imagePath;

  const VehicleModel({
    required this.id,
    required this.name,
    required this.tireCount,
    required this.imagePath,
  });

  // Gerçek araç listesi
  static List<VehicleModel> demoVehicles() {
    return [
      // Euclıd 1-12 (6 Lastik)
      ...List.generate(12, (i) => VehicleModel(
        id: 'euclid_${i + 1}',
        name: 'Euclıd-${i + 1}',
        tireCount: 6,
        imagePath: 'assets/images/truck_damper.png',
      )),
      // Lıugong 16-20 (10 Lastik)
      ...List.generate(5, (i) => VehicleModel(
        id: 'liugong_${i + 16}',
        name: 'Lıugong-${i + 16}',
        tireCount: 10,
        imagePath: 'assets/images/truck_damper.png',
      )),
      // XCMG 13-15 (10 Lastik)
      ...List.generate(3, (i) => VehicleModel(
        id: 'xcmg_${i + 13}',
        name: 'XCMG-${i + 13}',
        tireCount: 10,
        imagePath: 'assets/images/truck_damper.png',
      )),
    ];
  }
}

class TireRecord {
  final int tireNumber;
  String serialNumber;
  DateTime lastChangedDate;
  bool isChanged; // bu oturumda değiştirildi mi?

  TireRecord({
    required this.tireNumber,
    required this.serialNumber,
    required this.lastChangedDate,
    this.isChanged = false,
  });

  TireRecord copyWith({
    String? serialNumber,
    DateTime? lastChangedDate,
    bool? isChanged,
  }) {
    return TireRecord(
      tireNumber: tireNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      lastChangedDate: lastChangedDate ?? this.lastChangedDate,
      isChanged: isChanged ?? this.isChanged,
    );
  }
}
