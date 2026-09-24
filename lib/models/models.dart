import 'package:flutter/foundation.dart';

/// Yağ Takviyesi ekranındaki kayıt grubu.
enum OilCategory {
  /// Adblue, Antifriz, Motor, Hidrolik ... gibi yağ/sıvı takviyeleri.
  refill('Yağ Takviyeleri', 'Yağ Takviyesi', 'Yağ Takviyesi Türü'),

  /// Bom, Kova, Pimler ... gibi manuel (gresli) yağlama noktaları.
  manual('Manuel Yağlamalar', 'Manuel Yağlama', 'Manuel Yağlama Türü');

  const OilCategory(this.pluralLabel, this.label, this.columnLabel);

  /// Sekme başlığı, ör. "Manuel Yağlamalar".
  final String pluralLabel;

  /// Tekil ad, ör. "Manuel Yağlama".
  final String label;

  /// Tablodaki tür sütununun başlığı.
  final String columnLabel;
}

/// Bir araçta yağ takviyesi / manuel yağlama yapılan alan.
@immutable
class OilArea {
  const OilArea({
    required this.id,
    required this.name,
    required this.category,
    this.defaultAmount = 0,
  });

  /// YT-01 / MN-03 gibi alan kodu.
  final String id;

  /// Motor, Hidrolik, Gres, Paletler ... (yapılan takviyenin türü).
  final String name;

  /// Alanın hangi grupta listeleneceği.
  final OilCategory category;

  /// Litre cinsinden varsayılan takviye miktarı.
  final double defaultAmount;

  /// Listede gösterilen etiket: `Motor (YT-09)`
  String get label => '$name ($id)';
}

/// Sahadaki bir araç / iş makinesi.
/// Lastik ve yağ yapılandırması `lib/data/fleet.dart` içinde tanımlanır.
@immutable
class Vehicle {
  const Vehicle({
    required this.id,
    required this.code,
    required this.type,
    required this.site,
    required this.tirePositions,
    required this.oilAreas,
  });

  /// Kayıt anahtarı.
  final String id;

  /// Ekranda görünen araç adı, ör. Euclid-1
  final String code;

  /// ROCK_TRUCK, MINING_TRUCK, EXCAVATOR ...
  final String type;

  /// Çalıştığı saha / ocak.
  final String site;

  /// Aracın lastik konumları; listenin uzunluğu lastik sayısını verir.
  final List<String> tirePositions;

  /// Yağ takviyesi yapılan alanlar.
  final List<OilArea> oilAreas;

  int get tireCount => tirePositions.length;

  String get typeLabel => switch (type) {
        'ROCK_TRUCK' => 'K. Kamyon',
        'MINING_TRUCK' => 'Maden Kamyonu',
        'EXCAVATOR' => 'Ekskavatör',
        'LOADER' => 'Yükleyici',
        'MIXER' => 'Mikser',
        'DOZER' => 'Dozer',
        'TRUCK_ELECTRIC' => 'E.Kamyon',
        'LOADER_ELECTRIC' => 'Loder Elektrikli',
        'SHOVEL' => 'Shovel',
        'EXCAVATOR_DIESEL' => 'Ekskavatör Dizel',
        'EXCAVATOR_ELECTRIC' => 'Ekskavatör Elektrikli',
        _ => type,
      };

  /// Araç seçim listelerindeki filtre çiplerinde kullanılan geniş grup.
  /// `type` ayrıntılı kalır (etiket ve mining-be eşleştirmesi için); bu
  /// yalnızca filtre görünümü içindir. `Shovel` de Ekskavatör'e girer.
  String? get category => vehicleCategoryOf(type);
}

/// [Vehicle.category] ve `VehicleModel.category` (Lastik Değişimi kataloğu)
/// aynı gruplamayı kullansın diye ortak fonksiyon.
String? vehicleCategoryOf(String type) => switch (type) {
      'TRUCK_ELECTRIC' || 'ROCK_TRUCK' || 'MINING_TRUCK' => 'Kamyon',
      'SHOVEL' ||
      'EXCAVATOR_DIESEL' ||
      'EXCAVATOR_ELECTRIC' ||
      'EXCAVATOR' =>
        'Ekskavatör',
      'LOADER_ELECTRIC' || 'LOADER' => 'Loder',
      _ => null,
    };

/// Filtre çiplerinin gösterileceği sabit sıra.
const List<String> vehicleCategoryOrder = <String>['Kamyon', 'Ekskavatör', 'Loder'];

/// Lastik Değişimi ekranındaki bir satır.
class TireRecord {
  TireRecord({
    required this.tireId,
    required this.serialNo,
    required this.position,
    this.lastChangeDate,
    this.lastCheckDate,
  });

  final String tireId;

  /// Lastik değişiminde takılan yeni lastiğin seri numarası ile güncellenir.
  String serialNo;

  /// Sol ön, sağ arka gibi konum bilgisi (liste okunurluğu için).
  final String position;

  DateTime? lastChangeDate;
  DateTime? lastCheckDate;
}

/// Yağ Takviyesi ekranındaki bir satır.
class OilRecord {
  OilRecord({
    required this.areaId,
    required this.oilType,
    required this.category,
    required this.amount,
    this.lastOilDate,
    this.lastCheckDate,
  });

  /// Alan kodu, ör. YT-09.
  final String areaId;

  /// Takviye / yağlama türü, ör. "Motor", "Paletler". Satıra sabittir.
  final String oilType;

  /// Kaydın hangi grupta listelendiği.
  final OilCategory category;

  /// Litre cinsinden kullanılan yağ miktarı.
  double amount;
  DateTime? lastOilDate;

  /// Son takviyede kullanılan ürün. Seviye kontrolü gönderilirken de
  /// bildirilir; hiç takviye yapılmamışsa boştur.
  String lastProduct = '';

  /// Seviye kontrolünün yapıldığı son tarih ("Kontrol Et").
  DateTime? lastCheckDate;

  /// Kayıtların tam adı: `Motor (YT-09)`
  String get label => '$oilType ($areaId)';
}

enum NotificationKind { info, tire, oil, form, warning }

class NotificationItem {
  NotificationItem({
    required this.title,
    required this.message,
    required this.date,
    this.kind = NotificationKind.info,
    this.read = false,
    this.vehicleCode,
    this.details = const <String, String>{},
  });

  final String title;
  final String message;
  final DateTime date;
  final NotificationKind kind;

  /// İşlemin yapıldığı araç; geçmiş penceresinde ayrı satırda gösterilir.
  final String? vehicleCode;

  /// İşlemin ayrıntıları (alan adı -> değer). Geçmiş penceresinde kayda
  /// tıklanınca eklendiği sırayla listelenir; boşsa yalnızca [message] görünür.
  final Map<String, String> details;

  bool read;
}

/// Giriş yapan kullanıcı.
@immutable
class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.registryNo,
    required this.machineCode,
    required this.machineType,
  });

  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String registryNo;
  final String machineCode;
  final String machineType;

  /// NIMO API'sinin döndüğü kullanıcı gövdesi.
  /// Alan adları backend ile netleştikçe burada güncellenir.
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        fullName: json['fullName'] as String? ?? json['name'] as String? ?? json['firstName'] as String? ?? '',
        email: json['email'] as String? ?? json['mail'] as String? ?? '',
        phone: json['phone'] as String? ?? json['phoneNumber'] as String? ?? '',
        role: (json['role'] is Map ? json['role']['name'] as String? : json['role'] as String?) ?? json['title'] as String? ?? '',
        registryNo: json['registryNo'] as String? ?? json['id']?.toString() ?? '',
        machineCode: json['machineCode'] as String? ?? '',
        machineType: json['machineType'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'registryNo': registryNo,
        'machineCode': machineCode,
        'machineType': machineType,
      };

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? registryNo,
    String? machineCode,
    String? machineType,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      registryNo: registryNo ?? this.registryNo,
      machineCode: machineCode ?? this.machineCode,
      machineType: machineType ?? this.machineType,
    );
  }

  String get initials {
    final List<String> parts =
        fullName.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters2(2);
    return '${parts.first.characters2(1)}${parts.last.characters2(1)}';
  }
}

extension on String {
  String characters2(int n) => length <= n ? toUpperCase() : substring(0, n).toUpperCase();
}

// ---------------------------------------------------------------- işlem geçmişi

enum ActivityType { tireChange, oilRefill, serviceReport }

/// Kullanıcının yaptığı bir işlem. Anasayfadaki "Son İşlemler" listesini besler.
/// Alt türlerin her biri kendi detay alanlarını taşır.
sealed class ActivityRecord {
  ActivityRecord({required this.id, required this.vehicleCode, required this.date});

  final String id;
  final String vehicleCode;

  /// İşlemin (veya gruplanmış işlemin son adımının) zamanı.
  DateTime date;

  ActivityType get type;

  /// Listede görünen başlık.
  String get title;

  /// Listede başlığın altında görünen tek satırlık özet.
  String get summary;
}

/// Tek bir lastik değişiminin detayı.
class TireChangeDetail {
  const TireChangeDetail({
    required this.tireId,
    required this.serialNo,
    required this.position,
    required this.changedAt,
    required this.lastCheckDate,
  });

  final String tireId;
  final String serialNo;
  final String position;
  final DateTime changedAt;
  final DateTime lastCheckDate;
}

/// Bir araçta aynı seansta değiştirilen lastikler tek kayıtta toplanır.
class TireChangeActivity extends ActivityRecord {
  TireChangeActivity({
    required super.id,
    required super.vehicleCode,
    required super.date,
    required this.tires,
  });

  final List<TireChangeDetail> tires;

  @override
  ActivityType get type => ActivityType.tireChange;

  @override
  String get title => 'Lastik Değişimi';

  @override
  String get summary => '$vehicleCode • ${tires.length} lastik';
}

class OilRefillActivity extends ActivityRecord {
  OilRefillActivity({
    required super.id,
    required super.vehicleCode,
    required super.date,
    required this.area,
    required this.oilType,
    required this.amount,
  });

  /// Takviye yapılan bölge / alan.
  final String area;
  final String oilType;

  /// Litre. Gönderilmeyi bekleyen takviye düzeltilirse güncellenir.
  double amount;

  @override
  ActivityType get type => ActivityType.oilRefill;

  @override
  String get title => 'Yağ Takviyesi';

  @override
  String get summary => '$vehicleCode • $area • ${amount.toStringAsFixed(1)} L';
}

/// Servis Raporu ekranından gönderilen rapor.


class ServiceReportActivity extends ActivityRecord {
  ServiceReportActivity({
    required super.id,
    required super.vehicleCode,
    required super.date,
    required this.reportType,
    required this.description,
    required this.imagePaths,
    this.itemCount = 0,
  });

  /// Rapor türü, ör. "Lastik Değişim Raporu".
  final String reportType;
  final String description;
  final List<String> imagePaths;

  /// Rapora eklenen kayıt (lastik / yağ satırı) sayısı; arıza raporunda 0.
  final int itemCount;

  @override
  ActivityType get type => ActivityType.serviceReport;

  @override
  String get title => 'Servis Raporu';

  @override
  String get summary => '$reportType • ${imagePaths.length} görsel';
}

/// Servis Raporu ekranında seçilen görsel.
@immutable
class FormAttachment {
  const FormAttachment({required this.name, required this.path, this.bytes});

  final String name;
  final String path;
  final Uint8List? bytes;
}
