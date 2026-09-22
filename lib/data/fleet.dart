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

  /// 4 lastikli araçlar (loder): 1 ön aks + 1 arka aks, her köşede tek teker.
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

  /// Sahada kullanılabilecek yağ / gres ürünleri. Takviye penceresinde
  /// "Yağ Seçin" listesini doldurur: kullanıcı önce takviye türünü, sonra
  /// hangi ürünü kullandığını seçer.
  static const List<String> oilProducts = <String>[
    'M.YAĞ-PO MAXIGEAR EP 80W-90 185kg VARİL',
    'M.YAĞ-PO SUPER GRES EP-2 180kg VARİL',
    'M.YAĞ-PO MAXIGEAR EP-X 85W-140 185KG',
    'M.YAĞ-PO HYDRO-TECH HVI 46(1varil:180kg)',
    'M.YAĞ-MAXIM.TURBO DİZ.EXTRA 15W/40 DÖKME',
    'M.YAĞ-MAXIM.TURBO DİZ.EXTRA 15W/40 FIÇI 180Kg',
    'M.YAĞ-ANTİFRİZ ÖZEL VARİL KOD:13202-10YG 200Kg',
    'M.YAĞ-PO TMS OIL 973 PETROL OFİSİ 180',
    'M.YAĞ-TMS OIL 975 180',
    'M.YAĞ-HİDROLIK DOT4 (1paket:20x0,5lt)',
    'M.YAĞ-MOBİL ALMO527 PAIL 17.80KG(149872)',
    'M.YAĞ-PO ATF II (180kg) PETROL OFİSİ',
    'M.YAĞ-PO HYDRO-TECH HVI TX 32 175',
    'M.YAĞ-PO MOLIBDENLI GRES 2 (1tnk:15kg)',
    'M.YAĞ-CAM SUYU KATKISI KIŞLIK/Mono etilen gliko 30Kg',
    'M.YAĞ-NEW HOLLA.Hİ SPEC 10W30 ŞANZIMAN',
    'M.YAĞ-PO FULLGEAR 85W-90  LS 185 Kg',
    'M.YAĞ-KP 3 E-10 KAUÇUKLU GRES 3 DIN51825 14Kg',
    'ADBLUE KATKI MADDESİ (10 L HUNİLİ)',
    'DYNATRANS MPV    185K   TOT   TR',
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
        // Euclid — 6 lastik. 1/2 ve 9-12 "Elektrikli Kamyon", 3-8 "Kaya Kamyonu".
        for (int i = 1; i <= 12; i++)
          _vehicle(
            code: 'Euclid-$i',
            type: (i >= 3 && i <= 8) ? 'ROCK_TRUCK' : 'TRUCK_ELECTRIC',
            positions: tires6,
          ),

        // XCMG — 10 lastik, Elektrikli Kamyon.
        for (int i = 13; i <= 15; i++)
          _vehicle(
            code: 'XCMG-$i',
            type: 'TRUCK_ELECTRIC',
            positions: tires10,
          ),

        // Liugong — 10 lastik, Elektrikli Kamyon.
        for (int i = 16; i <= 20; i++)
          _vehicle(
            code: 'Liugong-$i',
            type: 'TRUCK_ELECTRIC',
            positions: tires10,
          ),

        // Liugong loderler — 4 lastik, Loder Elektrikli.
        for (int i = 33; i <= 39; i++)
          _vehicle(
            code: 'Liugong-$i',
            type: 'LOADER_ELECTRIC',
            positions: tires4,
          ),

        // Paletli araçlar — lastiği yok. Lastik Değişimi ekranında hiç
        // listelenmezler (bkz. lib/models/tire_change_model.dart — bu
        // araçlar o kataloğa eklenmez); diğer ekranlarda normal araç gibi
        // görünürler.
        //
        // Hitachi: 1200/1800/1900 "Shovel", 490 serisi "Ekskavatör Dizel".
        for (final String n in <String>['1200', '1800', '1900'])
          _vehicle(code: 'Hitachi-$n', type: 'SHOVEL', positions: <String>[]),
        for (final String n in <String>['490-1', '490-2'])
          _vehicle(code: 'Hitachi-$n', type: 'EXCAVATOR_DIESEL', positions: <String>[]),

        // Sany — hepsi Ekskavatör Dizel.
        for (int i = 68; i <= 70; i++)
          _vehicle(code: 'Sany-$i', type: 'EXCAVATOR_DIESEL', positions: <String>[]),

        // Liugong paletli: 6/7 Ekskavatör Dizel, 40/41 Loder Elektrikli.
        for (final String n in <String>['6', '7'])
          _vehicle(code: 'Liugong-$n', type: 'EXCAVATOR_DIESEL', positions: <String>[]),
        for (final String n in <String>['40', '41'])
          _vehicle(code: 'Liugong-$n', type: 'LOADER_ELECTRIC', positions: <String>[]),

        // Komatsu: 4/5/K6/K7 Ekskavatör Dizel, K8 Ekskavatör Elektrikli.
        // K9 sunucuda hiç yok; filodan çıkarıldı.
        for (final String n in <String>['4', '5', 'K6', 'K7'])
          _vehicle(code: 'Komatsu-$n', type: 'EXCAVATOR_DIESEL', positions: <String>[]),
        _vehicle(code: 'Komatsu-K8', type: 'EXCAVATOR_ELECTRIC', positions: <String>[]),
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
