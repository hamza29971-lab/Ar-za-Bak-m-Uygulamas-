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

  // Demo araç listesi
  static List<VehicleModel> demoVehicles() {
    return [
      const VehicleModel(
        id: 'damper_01',
        name: 'Damper-01',
        tireCount: 4,
        imagePath: 'assets/images/truck_damper.png',
      ),
      const VehicleModel(
        id: 'damper_02',
        name: 'Damper-02',
        tireCount: 4,
        imagePath: 'assets/images/truck_damper.png',
      ),
      const VehicleModel(
        id: 'damper_03',
        name: 'Damper-03',
        tireCount: 6,
        imagePath: 'assets/images/truck_damper.png',
      ),
      const VehicleModel(
        id: 'minibus_01',
        name: 'Minibüs-01',
        tireCount: 4,
        imagePath: 'assets/images/truck_damper.png',
      ),
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
