import '../models/models.dart';

/// Filo tanımlarının tek kaynağı.
///
/// Araçların lastik sayıları, lastiklerin konumları ve yağ takviyesi yapılan
/// alanlar burada tanımlanır; ekranlar bu tanımları kullanır. Yeni araç eklemek
/// veya bir aracın lastik/yağ yapılandırmasını değiştirmek için **yalnızca bu
/// dosya** düzenlenir.
class Fleet {
  Fleet._();

  // -------------------------------------------------------- lastik konumları

  /// 4 lastikli araçlar (loder/yükleyici): 1 ön aks + 1 arka aks.
  static const List<String> tires4 = <String>[
    'Sol Ön',
    'Sağ Ön',
    'Sol Arka',
    'Sağ Arka',
  ];

  /// 6 lastikli araçlar (kaya kamyonu): 1 ön aks + 1 çift teker arka aks.
  static const List<String> tires6 = <String>[
    'Sol Ön',
    'Sağ Ön',
    'Sol Arka Dış',
    'Sol Arka İç',
    'Sağ Arka İç',
    'Sağ Arka Dış',
  ];

  /// 10 lastikli araçlar: 1 ön aks + 2 çift tekerli aks.
  static const List<String> tires10 = <String>[
    'Sol Ön',
    'Sağ Ön',
    'Sol Orta Dış',
    'Sol Orta İç',
    'Sağ Orta İç',
    'Sağ Orta Dış',
    'Sol Arka Dış',
    'Sol Arka İç',
    'Sağ Arka İç',
    'Sağ Arka Dış',
  ];

  // ------------------------------------------------------------- yağ alanları

  /// "Yağ Takviyeleri" grubunda yapılabilecek takviye türleri.
  static const List<OilArea> oilRefillAreas = <OilArea>[
    OilArea(id: 'YT-01', name: 'Adblue', category: OilCategory.refill),
    OilArea(id: 'YT-02', name: 'Antifriz', category: OilCategory.refill),
    OilArea(id: 'YT-03', name: 'Cer', category: OilCategory.refill),
    OilArea(id: 'YT-04', name: 'Diferansiyel', category: OilCategory.refill),
    OilArea(id: 'YT-05', name: 'Direksiyon', category: OilCategory.refill),
    OilArea(id: 'YT-06', name: 'Gres', category: OilCategory.refill),
    OilArea(id: 'YT-07', name: 'Hidrolik', category: OilCategory.refill),
    OilArea(id: 'YT-08', name: 'Kule dönüş', category: OilCategory.refill),
    OilArea(id: 'YT-09', name: 'Motor', category: OilCategory.refill),
    OilArea(id: 'YT-10', name: 'Muhtelif', category: OilCategory.refill),
    OilArea(id: 'YT-11', name: 'Pompa_Şanzıman', category: OilCategory.refill),
    OilArea(id: 'YT-12', name: 'Radyatör suyu', category: OilCategory.refill),
    OilArea(id: 'YT-13', name: 'Soğutma suyu', category: OilCategory.refill),
    OilArea(id: 'YT-14', name: 'Şanzıman', category: OilCategory.refill),
  ];

  /// "Manuel Yağlamalar" grubunda yapılabilecek yağlama türleri.
  static const List<OilArea> manualLubricationAreas = <OilArea>[
    OilArea(id: 'MN-01', name: 'Arm', category: OilCategory.manual),
    OilArea(id: 'MN-02', name: 'Bom', category: OilCategory.manual),
    OilArea(id: 'MN-03', name: 'Diferansiyel yağlama', category: OilCategory.manual),
    OilArea(id: 'MN-04', name: 'Komple manuel yağlama', category: OilCategory.manual),
    OilArea(id: 'MN-05', name: 'Kova', category: OilCategory.manual),
    OilArea(id: 'MN-06', name: 'Paletler', category: OilCategory.manual),
    OilArea(id: 'MN-07', name: 'Pimler', category: OilCategory.manual),
    OilArea(id: 'MN-08', name: 'Muhtelif', category: OilCategory.manual),
  ];

  /// Tüm araçlarda ortak alanlar: önce yağ takviyeleri, sonra manuel yağlamalar.
  static const List<OilArea> standardOilAreas = <OilArea>[
    ...oilRefillAreas,
    ...manualLubricationAreas,
  ];

  /// Bir grubun alan listesi.
  static List<OilArea> areasOf(OilCategory category) =>
      category == OilCategory.refill ? oilRefillAreas : manualLubricationAreas;

  // ------------------------------------------------------------------- araçlar

  /// Sahadaki tüm araçlar.
  static List<Vehicle> vehicles() => <Vehicle>[
        // Euclid kaya kamyonları — 6 lastik
        for (int i = 1; i <= 12; i++)
          _vehicle(
            code: 'Euclid-$i',
            type: 'ROCK_TRUCK',
            positions: tires6,
          ),

        // XCMG maden kamyonları — 10 lastik
        for (int i = 13; i <= 15; i++)
          _vehicle(
            code: 'XCMG-$i',
            type: 'MINING_TRUCK',
            positions: tires10,
          ),

        // Liugong maden kamyonları — 10 lastik
        for (int i = 16; i <= 20; i++)
          _vehicle(
            code: 'Liugong-$i',
            type: 'MINING_TRUCK',
            positions: tires10,
          ),
        // Liugong loder tipi — 4 lastik
        for (int i = 33; i <= 39; i++)
          _vehicle(
            code: 'Liugong-$i',
            type: 'LOADER',
            positions: tires4,
          ),
      ];

  static Vehicle _vehicle({
    required String code,
    required String type,
    required List<String> positions,
    String site = 'Maden Sahası',
    List<OilArea> oilAreas = standardOilAreas,
  }) =>
      Vehicle(
        id: code.toLowerCase(),
        code: code,
        type: type,
        site: site,
        tirePositions: positions,
        oilAreas: oilAreas,
      );
}
