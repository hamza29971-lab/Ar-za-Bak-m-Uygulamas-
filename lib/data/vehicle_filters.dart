import '../models/models.dart';

/// Araçlara ait filtre tanımları (Excel: Nimo Yeni Filtre Taslağı).
///
/// Yağ takviyesi ekranında aracın modeline göre doğru filtre seçeneklerini sunar.
class VehicleFilters {
  VehicleFilters._();

  /// 05-01-IM-KK-EUCLID.01
  static const List<String> _filtersGroup1 = <String>[
    '4881175-AF 883M İÇ HAVA FİLT. MIC-EUC',
    'HAVA FİLTRESİ DIŞ 4881174-AF 851M MIC-',
  ];

  /// 05-01-IM-KK-EUCLID.01, … 07 ve 08
  static const List<String> _filtersGroup2 = <String>[
    '12578201 STRAINER',
    'HİDROLİK F N0281700272 4099537-HF 30518 HİDROLİK FİLT.',
    '4084679 KABİN HAVA FİLT. EUC R 85',
    'HİDROLİK HVL F N0281700312 HİDROLİK HAVALANDIRMA FİLTRESİ EUC902949',
    '4042098 DİREKSİY. HAV.FİL. EUC AF 1949',
    '4099538 DİREKSİYON FİLT. EUC',
  ];

  /// 05-01-IM-KK-HTC.EUC.09, 10, 11 ve 12
  static const List<String> _filtersGroup3 = <String>[
    'HİDROLİK HV F (STRAİNER) EUC902949',
    'DİREKSYN HVL F 4042098 AF 1949',
    'HİDROLİK-DAMPER KALDIRC F HEE12981312',
    'DİREKSİYON F HEE12981311 HTC EUC',
    'HİDROLİK TANK HV F HEE12649035 HTC EUC',
    'KLİMA FİLİTRESİ HEE12981647 HTC EUC',
    'KABİN FİLİTRESİ HEE12981624 HTC EUC',
  ];

  /// 05-01-IM-KK-XCMG.E.13, 14 ve 15
  static const List<String> _filtersGroup4 = <String>[
    'DİREKSİYON FİLT. WX860176641 CMX',
    'DIŞ KABİN FİLT. WX813500270 CMX',
    'İÇ KABİN FİLT. WX803403535 CMX',
    'HİDROLİK DÖN.FİLT. WX860176645 CMX',
    'HİDROLİK TANK FİLT. WX813403619 CMX',
    'HAVA KOMPRESÖR FİLT. WX800177544',
    'KOMPRESÖR FİLT. WX800177542 CMX',
  ];

  /// LİUGONG_EL_16, 17, 18, 19 VE 20
  static const List<String> _filtersGroup5 = <String>[
    'KOMPRESÖR YAĞ FİLTRESİ SP348616',
    'KOMPRESÖR HAVA FİLTRESİ SP253083',
    'KLİMA FİLTRESİ İÇ 53C2167',
    'KLİMA FİLTRESİ DIŞ SP270039',
    'HİDROLİK DÖNÜŞ FİLTRESİ 53C0463',
    'HİDROLİK HAVALANDIRMA FİLTRESİ FİLTRESİ SP234061',
  ];

  /// 05-03-IM-LM-HTC.31.441
  static const List<String> _filtersGroup6 = <String>[
    'FİLTRE DIŞ HAVA BC3098070430 HIT ZW310',
    'FİLTRE İÇ HAVA BC3098070440 HIT ZW 310',
    'HİDROLİK FİLTRE HYA00033065 HIT ZW 310',
    'KLİMA FİLTRESİ HH4251527 HIT ZW 310',
    'MOTOR YAĞ FİLTRESİ BC3406809 HIT ZW 310',
    'SU FİLTRESİ BCYEWF2071 HIT ZW 310',
    'ŞANZIMAN FİLTRE HH3111570040 HIT ZW 310',
    'YAKIT FİLTRESİ BC4377880 HIT ZW 310',
    'KABİN FİLTRE ZW310 DENSO 0143005210',
  ];

  /// 05-03-IM-LM-KAWSK.135
  static const List<String> _filtersGroup7 = <String>[
    'AF 1922 -P127309 İÇ HAVFİL KW.135 CH1343',
    'AF1921 P127308 DIŞ HAV.FİL KW135 CH 1342',
    'HİDROLİK FİİLTRE 30981-60100',
    'HİDROLİK ELMNT F 4219713 HF 7953',
    '4033060270 KABİN FİLTRESİ',
    '4033070380 KLİMA FİLTRESİ(KAWASAKİ)',
    'MANYETİK FİLTRE KAWASAKİ 135 40335-60130',
    'MOTOR YAĞ FİLT. 12979663-LF 9080 CS0091',
    '12565210-WF 2075 SU FİLT. EUC BW 5075',
    'ŞANZ. FİLT. ATOM TİP 4034470040 KAWAS',
    'ŞANZ.FİLT. 3098170620 KAWAS',
    'P552216-FS 1216 MAZOT FİLT. (MUSLUKLU)',
  ];

  /// 05-03-IM-LM-VOL29.8243
  static const List<String> _filtersGroup8 = <String>[
    '4881323-AF 4895 DİFR.ŞANZ.HAVALN.FİLT.',
    '11998302-HF 28805 HİDROLİK FİLT L-180',
    '466634-LF 667 YAĞ FİLTRESİ',
    'HAVA FİL.İÇ 11033999-AF 25620-RS 3827',
    'HAVA FİLT.DIŞ 11033998-AF 25619(L-180)',
    'KLİMA FİLT 11703979 VOL16-17 PA 5310',
    'KABİN FİLT 11703980 VOL 16-17 PA 4991',
    '11110683 SU AYIR.FİL.VOL G 7747 FS 19591',
    '11037868 ŞANZIMAN FİLT. - VOL16-17 BT887',
    '17438617 HİDROLİK FİLTRE',
    '6211489 DİFERANSİYEL FİLT. VLV 21-2-3-4',
    '15126069 YAKIT FİLTRESİ VLV 21-2-3-4',
    'YAĞ FİL.BYPASS-477556-LF 3654 B 7685',
    '12-0007 HİDR.HAVAL FİLTRESİ VOLVO 16-17',
    '11445028 HİDROLİK FİLTRE',
  ];

  /// 05-03-IM-LM-LIUG.EL.33, 34, 35, 36 VE 37
  static const List<String> _filtersGroup9 = <String>[
    'FİLTRE KLİMA DIŞ 35C1456 LİU-GONG',
    'FİLTRE KLİMA İÇ SP296456 LİU-GONG',
    'FİLTRE HİDR.DÖNŞ. 53C1544 LİU-GONG 856',
    'FİLTRE HİDR.PİLOT 53C0631 LİU GONG 856',
    'FİLTRE ŞANZ.YAĞ DIŞ 53C1837 LİU GONG',
    'FİLTRE ŞANZ.YAĞ İÇ 53C1933 LİU GONG',
    'FİLTRE HİDR.DÖNŞ. 53C1844 LİU GONG 870',
    'FİLTRE HİDR.PİLOT SP260216 LİU GONG 870',
  ];

  /// 05-03-IM-LM-LIUG.EL.38, 39, 40 VE 41
  static const List<String> _filtersGroup10 = <String>[
    'FİLTRE KLİMA DIŞ 35C1456 LİU-GONG',
    'FİLTRE KLİMA İÇ SP296456 LİU-GONG',
    'FİLTRE ŞANZ.YAĞ DIŞ 53C1837 LİU GONG',
    'FİLTRE ŞANZ.YAĞ İÇ 53C1933 LİU GONG',
    'FİLTRE HİDR.DÖNŞ. 53C1844 LİU GONG 870',
    'FİLTRE HİDR.PİLOT SP260216 LİU GONG 870',
  ];

  /// 05-05-IM-PM-HITC.350.1 ve 2
  static const List<String> _filtersGroup11 = <String>[
    'HP 2582 DIŞ HAVA FİL. HİTACHİ 350',
    'HP 2583 İÇ HAVA FİL. HİTACHİ 350',
    'KLİMA FİLT. ÖZEL HITC-350 4S00686 LHE',
    'KABİN FİLT. ÖZEL HITC 350 4S00685',
    '8981354621 MAZOT SU AYIRC. HITC 350',
    '4676385 MAZOT FİLTRESİ HITC 350',
    '00016054 HİDROLİK FİLT. HITC 350',
    '4630525 PİLOT FİLT. HITC 350',
    'MOTOR YAĞ F',
  ];

  /// 05-05-IM-PM-HITC.490.1 ve 2
  static const List<String> _filtersGroup12 = <String>[
    'HAVA FİLTRESİ DIŞ / İÇ JFX770629 710',
    'KABİN FİLTRESİ HHYA00032683',
    'KLİMA FİLTRESİ HHYA00001490',
    'HİDROLİK FİLTRE HH4654745',
    'STRAİNER FİLTRE HH4317008',
    'YAĞ FİLTRESİ HH4696643 YA00086177',
    'YAKIT FİLTRESİ I8983129180',
    'YAKIT FİLTRESİ HHYA00047220',
    'YAKIT FİLTRESİ HHYA00002973',
    'PİLOT FİLTRE HH4630525',
    'DRAİN FİLTRESİ JFP555570',
    'HİDROLİK FİLTRE 4363399 CARTRINGE DRAİİN',
  ];

  /// 05-05-IM-PM-HITCEX1200
  static const List<String> _filtersGroup13 = <String>[
    'KABİN FİLTRESİ 4206637',
    'HİDROLİK DÖNÜŞ F 4333469 HIT.1900 HF28910',
    'KLİMA FİLTRESİ 4441139 (HITC.1200)',
    'KABİN FİLTRESİ 4458781 (HITC.1200)',
    'KABİN FİLTRESİ ÖZEL',
    'HİDROLİK F HİDROLİK FİLTRE ÖZEL (KÜÇÜK)',
  ];

  /// 05-05-IM-PM-HITCEX1800
  static const List<String> _filtersGroup14 = <String>[
    'HİDROLİK ELMNT F 4219713 HF 7953',
    'KABİN KLİMA FİLTRESİ 4206637',
    'HİDROLİK PİLOT F 3021593-HF 7918',
  ];

  /// 05-05-IM-PM-HITCEX1900
  static const List<String> _filtersGroup15 = <String>[
    'HİDROLİK ELEMEN F',
    'HİDROLİK BY-PASS F 4185299 HF 28879',
    'HİDROLİK EMİŞT TANK F 4432753',
    'HİDROLİK PİLOT F 3501404 HF 7922',
    'KABİN KLİMA FİLTRESİ',
  ];

  /// 05-05-IM-PM-KOMT.450.3
  static const List<String> _filtersGroup16 = <String>[
    'HİDR TANK HVL F 421-60-35170 KOMATS 450',
    'HİDROLİK FİLTRESİ 208-60-71123 KOM 450',
    'KLİMA F N0285000214 208-979-7620 C 1121',
    'FİLTRE(KLİMA FİLT.)17M-911-3530',
  ];

  /// KOMATSU PC 450 LC - 8 N0281701786
  static const List<String> _filtersGroup17 = <String>[
    'FİLTRE(HİD.TANK HAV FİLT.)20Y-60-21470',
  ];

  /// 05-05-IM-PM-KOMT.850.4 ve 5
  static const List<String> _filtersGroup18 = <String>[
    'FİLTRE(DRAIN FİLT.)209-60-76210',
    'FİLTRE(PİLOT FİLT.)21T-60-31410',
    'FİLTRE(HİD.TANK HAV FİLT.)20Y-60-21470',
    'FİLTRE(HİDROLİK FİLT.)209-60-77532',
    'FİLTRE(KLİMA FİLT.)208-979-7620 C 1121',
    'FİLTRE(KLİMA FİLT.)17M-911-3530',
    'HİDROLİK DÖNÜŞ F',
    'HİDRLK TANK KAPAK O-RİNGİ',
  ];

  /// 05-05-IM-PM-KOMT.550.6, 7 ve 8
  static const List<String> _filtersGroup19 = <String>[
    'HİDROLİK FİLTRESİ 208-60-71123 KOM 450',
    'FİLTRE(HİDROLİK FİLT.)209-60-77532',
    'FİLTRE(DRAIN FİLT.)209-60-76210',
    'HİDROLİK DÖNÜŞ F',
    'HİDROLİK FİLTRE 208-60-71124 KOM 550 6.9',
    'FİLTRE(HİD.TANK HAV FİLT.)20Y-60-21470',
    'HİDRLK TANK KAPAK O-RİNGİ',
    'FİLTRE(KLİMA FİLT.)17M-911-3530',
    'FİLTRE(KLİMA FİLT.)208-979-7620 C 1121',
  ];

  /// 05-05-IM-PM-KOM.390.12
  static const List<String> _filtersGroup20 = <String>[
    'TANK HAVALANDIRMA FİLTRESİ 421-60-35170',
    'HİDROLİK FİLTRESİ 207-60-71182',
    'YAĞ FİLTRE 6742-01-4540',
    'YAKIT ANA FİLTRE 600-319-3750',
    'YAKIT ÖN FİLTRE 600-319-3610',
    'KLİMA FİLTRESİ 17M-911-3530',
    'HAVA FİLTRESİ İÇ/DIŞ 600-185-4200',
    'KABİN FİLTRESİ 2A5-979-1551',
    'HİDROLİK O-RİNGİ 07000-15170',
  ];

  /// 05-05-IM-PM-LIUGONG.33 ve 34
  static const List<String> _filtersGroup21 = <String>[
    'MOTOR YAĞ FİLTRESİ LF9070 / 40C5067',
    'MOTOR YAKIT FİLTRESİ FF63010 / 40C9582',
    'MOTOR SU AYIRICI FİLTRESİ 53C2328 / FS53075',
    'MOTOR SU AYIRICI FİLTRESİ FS19765 / 40C9582',
    'MOTOR HAVA FİLTRESİ TAKIM 60C7942 / AF4403-AF4404',
    'HİDROLİK DÖNÜŞ FİLTRESİ 53C2061',
    'HİDROLİK EMİŞ FİLTRESİ 53C1487',
    'HİDROLİK PİLOT DÖNÜŞ FİLTRESİ 53C2423',
    'HİDROLİK PİLOT FİLTRESİ 53C0083',
    'KLİMA FİLTRESİ İÇ 46C6765',
    'KLİMA FİLTRESİ DIŞ 35C0827',
    'ADD BLUE TANK FİLTRE İÇ 53C1732',
    'ADD BLUE POMPA FİLTRESİ 37C1370',
  ];

  /// 05-05-IM-PM-SY.385H.68, 69 ve 70
  static const List<String> _filtersGroup22 = <String>[
    'FİLTRE ADBLUE POMP. SYUF 106-B SANY',
    'FİLTRE DEF.TANK SY160599000254A SANY',
    'FİLTRE HAVA DIŞ SYB222100000641-C SANY',
    'FİLTRE HAVA İÇ SYB222100000640-C SANY',
    'FİLTRE HİD.TNK.DNŞ SYGLQ008449764 SANY',
    'FİLTRE TNK EMŞ SÜZGC SY151502000062A SAN',
    'FİLTRE HİD.TNK.HVL. SY60186788 SANY',
    'FİLTRE KLİMA DIŞ SY141502000438B SANY',
    'FİLTRE KLİMA İÇ SYGLQ008359502 SANY',
    'FİLTRE KULE DNŞ.HAT SYGLQ008471460 SANY',
    'FİLTRE MOTOR YAĞ SYLF14009NN-B SANY',
    'FİLTRE PİLOT HAT SYGLQ009244827 SANY',
    'FİLTRE ŞASE YAKIT SYFS20121-B SANY',
    'FİLTRE YAKIT ANA SYFF63054NN-B SANY',
  ];

  /// 05-04-IM-DZ-CATER.GREY
  static const List<String> _filtersGroup23 = <String>[
    'MOTOR YAĞ F 1R0739 CAT 140M',
    'YAKIT F 1R0762 CAT-140M',
    'HİDROLİK ATOM F 3283655 3283655 CAT-140M',
    'HAVA DIŞ MOTOR 2456375 CAT-140M',
    'HAVA İÇ MOTOR 2456376 CAT-140M',
    'SU - ŞASE F 3261644 CAT 140M',
    'HİDROLİK ELEMENT F FILTR 1R1809',
    'KLİMA KABİN F 1491912 CAT 140',
    'KABİN KLİMA F 2112660 CAT 140',
  ];

  /// CAT M 140 N02817008011
  static const List<String> _filtersGroup24 = <String>[
    'ŞANZUMAN F 1G8878',
  ];

  /// 05-04-IM-DZ-MITSU.GREY
  static const List<String> _filtersGroup25 = <String>[
    'AKH 8156 DIŞ HAVA FİLT. MG-530 HP 4017',
    'ME 056670-FF 5367 MAZOT FİL.MG-530',
    'AKY 8026-LF 3447 MOT.YAĞ FİL MG-530',
    'AF 976-35004-1 İÇ HAVA FİL MG 530',
    '58822-27400 FİLTRE MG-530',
    '34740-00100-LF 3382 ŞAN.YAĞ FİL MG530',
    'AKY 8024-LF 3432 BYPASS YAĞ FİL MG 530',
    '92576-14100 AKY 8846 HİDROLİK FİL. MG530',
  ];

  /// 05-04-IM-DZ-CATER.D9L
  static const List<String> _filtersGroup26 = <String>[
    'SU F 12565210-WF 2075 BW 5075',
    'HAVA DIŞ MOTOR 1W2516-HP 798',
    'HİDROLİK F 7J670 AKY 8314',
    'ŞANZUMAN F 1R0719 - HF 06097',
    'MOTOR YAĞ F 2P4005 SP425 LF 6910',
    'HAVA İÇ MOTOR 7N1308 - AF 874',
    'YAKIT F 4377880-FS 1000',
  ];

  /// 05-04-IM-DZ-CATER.D10N
  static const List<String> _filtersGroup27 = <String>[
    'KLİMA FİLTRESİ UZUN',
    'ŞANZUMAN F 1R0719 - HF 06097',
    'MOTOR YAĞ F 2P4005 SP425 LF 6910',
    'HAVA DIŞ MOTOR 7W9853 AF 4692',
    'HAVA İÇ MOTOR 7W9567 AF 4694',
    'HİDROLİK F 1R735 (AKY8385)',
    'YAKIT F 4377880-FS 1000',
  ];

  /// 05-02-IM-DL-ATLAST35.1
  static const List<String> _filtersGroup28 = <String>[
    'HAVA DIŞ MOTOR AF 25129 DIŞ HAVA FİLT. 2653207478 (T35)',
    'HAVA İÇ MOTOR 2653207460 - AF 25130 MOTOR İÇ FİLT T 35',
    'HAVA DIŞ KOMP P812924 KOMP.DIŞ HAVA Fİ AF 25957 - T35',
    'HAVA İÇ KOMP 2653207387 KOMP İÇ HAVA FİLT.(T35)',
    'HİDROLİK F HİDROLİK FİLTRE 53096434 ATLAS 580',
    'KLİMA KABİN F 5118641970 KABİN FİLT. ATLAS T 35',
    'KOMP YAĞ F 36897353 KOMPRES. YAĞ FİLT. ATLAS 580',
    'SU AYIRICI FİLTRESİ 2657828816 SU AYR.FİLT. (T 35) FS 19732',
    'TOZ-KARTUJ F 2653254470 FİLTER CARTRIDGE - T 35',
    'YAKIT F FF 5421 3978040',
    'SEPERATÖR - ELEMENT 22402358 ELEMENT - SEPERATÖR ATLAS',
    'SEPERATÖR YAĞ FİLTRESİ ( T35)',
  ];

  /// ATLAS T35 N0281790120
  static const List<String> _filtersGroup29 = <String>[
    'MOTOR YAĞ F N0281700381 LF 3970 HT 12059196',
  ];

  /// 05-02-IM-DL-ATLAST35.F
  static const List<String> _filtersGroup30 = <String>[
    '3222 1881 31/001-AIR FILTER X 1 3222 1881 41/001-HAVA FİL.İÇ-DIŞ KOMP',
    '3222 1881 41/001-AIR FILTER X 1 3222 1881 31/001HAVA FİLTRE İÇ-DIŞ MOTOR',
    '3222 3456 25/001-BREATHER FILTER X 2 3222 3456 25 BREATHER FILT',
    '3222 3253 76/001-FILTER X 1 3222 3253 76/001',
    '3222 3253 78/001-FILTER X 1 3222 3253 78/001',
    '3222 3320 81/002-FILTER ELEMENT X 11',
    '3216 9214 04/001-OIL FILTER X 1',
    '3222 3252 97/001-OIL FILTER X 1',
    '3222 3476 44/001-FUEL FILTER X 1',
    '3222 9861 46/001-AIR FILTER X 1',
    '3222 3246 42/001-FILTER X 1',
    '3222 3362 53/001-FUEL FILTER X 2',
  ];

  /// Tüm tanımlı filtrelerin listesi.
  static const List<String> allFilters = <String>[
    '4881175-AF 883M İÇ HAVA FİLT. MIC-EUC',
    'HAVA FİLTRESİ DIŞ 4881174-AF 851M MIC-',
    '12578201 STRAINER',
    'HİDROLİK F N0281700272 4099537-HF 30518 HİDROLİK FİLT.',
    '4084679 KABİN HAVA FİLT. EUC R 85',
    'HİDROLİK HVL F N0281700312 HİDROLİK HAVALANDIRMA FİLTRESİ EUC902949',
    '4042098 DİREKSİY. HAV.FİL. EUC AF 1949',
    '4099538 DİREKSİYON FİLT. EUC',
    'HİDROLİK HV F (STRAİNER) EUC902949',
    'DİREKSYN HVL F 4042098 AF 1949',
    'HİDROLİK-DAMPER KALDIRC F HEE12981312',
    'DİREKSİYON F HEE12981311 HTC EUC',
    'HİDROLİK TANK HV F HEE12649035 HTC EUC',
    'KLİMA FİLİTRESİ HEE12981647 HTC EUC',
    'KABİN FİLİTRESİ HEE12981624 HTC EUC',
    'DİREKSİYON FİLT. WX860176641 CMX',
    'DIŞ KABİN FİLT. WX813500270 CMX',
    'İÇ KABİN FİLT. WX803403535 CMX',
    'HİDROLİK DÖN.FİLT. WX860176645 CMX',
    'HİDROLİK TANK FİLT. WX813403619 CMX',
    'HAVA KOMPRESÖR FİLT. WX800177544',
    'KOMPRESÖR FİLT. WX800177542 CMX',
    'KOMPRESÖR YAĞ FİLTRESİ SP348616',
    'KOMPRESÖR HAVA FİLTRESİ SP253083',
    'KLİMA FİLTRESİ İÇ 53C2167',
    'KLİMA FİLTRESİ DIŞ SP270039',
    'HİDROLİK DÖNÜŞ FİLTRESİ 53C0463',
    'HİDROLİK HAVALANDIRMA FİLTRESİ FİLTRESİ SP234061',
    'FİLTRE DIŞ HAVA BC3098070430 HIT ZW310',
    'FİLTRE İÇ HAVA BC3098070440 HIT ZW 310',
    'HİDROLİK FİLTRE HYA00033065 HIT ZW 310',
    'KLİMA FİLTRESİ HH4251527 HIT ZW 310',
    'MOTOR YAĞ FİLTRESİ BC3406809 HIT ZW 310',
    'SU FİLTRESİ BCYEWF2071 HIT ZW 310',
    'ŞANZIMAN FİLTRE HH3111570040 HIT ZW 310',
    'YAKIT FİLTRESİ BC4377880 HIT ZW 310',
    'KABİN FİLTRE ZW310 DENSO 0143005210',
    'AF 1922 -P127309 İÇ HAVFİL KW.135 CH1343',
    'AF1921 P127308 DIŞ HAV.FİL KW135 CH 1342',
    'HİDROLİK FİİLTRE 30981-60100',
    'HİDROLİK ELMNT F 4219713 HF 7953',
    '4033060270 KABİN FİLTRESİ',
    '4033070380 KLİMA FİLTRESİ(KAWASAKİ)',
    'MANYETİK FİLTRE KAWASAKİ 135 40335-60130',
    'MOTOR YAĞ FİLT. 12979663-LF 9080 CS0091',
    '12565210-WF 2075 SU FİLT. EUC BW 5075',
    'ŞANZ. FİLT. ATOM TİP 4034470040 KAWAS',
    'ŞANZ.FİLT. 3098170620 KAWAS',
    'P552216-FS 1216 MAZOT FİLT. (MUSLUKLU)',
    '4881323-AF 4895 DİFR.ŞANZ.HAVALN.FİLT.',
    '11998302-HF 28805 HİDROLİK FİLT L-180',
    '466634-LF 667 YAĞ FİLTRESİ',
    'HAVA FİL.İÇ 11033999-AF 25620-RS 3827',
    'HAVA FİLT.DIŞ 11033998-AF 25619(L-180)',
    'KLİMA FİLT 11703979 VOL16-17 PA 5310',
    'KABİN FİLT 11703980 VOL 16-17 PA 4991',
    '11110683 SU AYIR.FİL.VOL G 7747 FS 19591',
    '11037868 ŞANZIMAN FİLT. - VOL16-17 BT887',
    '17438617 HİDROLİK FİLTRE',
    '6211489 DİFERANSİYEL FİLT. VLV 21-2-3-4',
    '15126069 YAKIT FİLTRESİ VLV 21-2-3-4',
    'YAĞ FİL.BYPASS-477556-LF 3654 B 7685',
    '12-0007 HİDR.HAVAL FİLTRESİ VOLVO 16-17',
    '11445028 HİDROLİK FİLTRE',
    'FİLTRE KLİMA DIŞ 35C1456 LİU-GONG',
    'FİLTRE KLİMA İÇ SP296456 LİU-GONG',
    'FİLTRE HİDR.DÖNŞ. 53C1544 LİU-GONG 856',
    'FİLTRE HİDR.PİLOT 53C0631 LİU GONG 856',
    'FİLTRE ŞANZ.YAĞ DIŞ 53C1837 LİU GONG',
    'FİLTRE ŞANZ.YAĞ İÇ 53C1933 LİU GONG',
    'FİLTRE HİDR.DÖNŞ. 53C1844 LİU GONG 870',
    'FİLTRE HİDR.PİLOT SP260216 LİU GONG 870',
    'HP 2582 DIŞ HAVA FİL. HİTACHİ 350',
    'HP 2583 İÇ HAVA FİL. HİTACHİ 350',
    'KLİMA FİLT. ÖZEL HITC-350 4S00686 LHE',
    'KABİN FİLT. ÖZEL HITC 350 4S00685',
    '8981354621 MAZOT SU AYIRC. HITC 350',
    '4676385 MAZOT FİLTRESİ HITC 350',
    '00016054 HİDROLİK FİLT. HITC 350',
    '4630525 PİLOT FİLT. HITC 350',
    'MOTOR YAĞ F',
    'HAVA FİLTRESİ DIŞ / İÇ JFX770629 710',
    'KABİN FİLTRESİ HHYA00032683',
    'KLİMA FİLTRESİ HHYA00001490',
    'HİDROLİK FİLTRE HH4654745',
    'STRAİNER FİLTRE HH4317008',
    'YAĞ FİLTRESİ HH4696643 YA00086177',
    'YAKIT FİLTRESİ I8983129180',
    'YAKIT FİLTRESİ HHYA00047220',
    'YAKIT FİLTRESİ HHYA00002973',
    'PİLOT FİLTRE HH4630525',
    'DRAİN FİLTRESİ JFP555570',
    'HİDROLİK FİLTRE 4363399 CARTRINGE DRAİİN',
    'KABİN FİLTRESİ 4206637',
    'HİDROLİK DÖNÜŞ F 4333469 HIT.1900 HF28910',
    'KLİMA FİLTRESİ 4441139 (HITC.1200)',
    'KABİN FİLTRESİ 4458781 (HITC.1200)',
    'KABİN FİLTRESİ ÖZEL',
    'HİDROLİK F HİDROLİK FİLTRE ÖZEL (KÜÇÜK)',
    'KABİN KLİMA FİLTRESİ 4206637',
    'HİDROLİK PİLOT F 3021593-HF 7918',
    'HİDROLİK ELEMEN F',
    'HİDROLİK BY-PASS F 4185299 HF 28879',
    'HİDROLİK EMİŞT TANK F 4432753',
    'HİDROLİK PİLOT F 3501404 HF 7922',
    'KABİN KLİMA FİLTRESİ',
    'HİDR TANK HVL F 421-60-35170 KOMATS 450',
    'HİDROLİK FİLTRESİ 208-60-71123 KOM 450',
    'KLİMA F N0285000214 208-979-7620 C 1121',
    'FİLTRE(KLİMA FİLT.)17M-911-3530',
    'FİLTRE(HİD.TANK HAV FİLT.)20Y-60-21470',
    'FİLTRE(DRAIN FİLT.)209-60-76210',
    'FİLTRE(PİLOT FİLT.)21T-60-31410',
    'FİLTRE(HİDROLİK FİLT.)209-60-77532',
    'FİLTRE(KLİMA FİLT.)208-979-7620 C 1121',
    'HİDROLİK DÖNÜŞ F',
    'HİDRLK TANK KAPAK O-RİNGİ',
    'HİDROLİK FİLTRE 208-60-71124 KOM 550 6.9',
    'TANK HAVALANDIRMA FİLTRESİ 421-60-35170',
    'HİDROLİK FİLTRESİ 207-60-71182',
    'YAĞ FİLTRE 6742-01-4540',
    'YAKIT ANA FİLTRE 600-319-3750',
    'YAKIT ÖN FİLTRE 600-319-3610',
    'KLİMA FİLTRESİ 17M-911-3530',
    'HAVA FİLTRESİ İÇ/DIŞ 600-185-4200',
    'KABİN FİLTRESİ 2A5-979-1551',
    'HİDROLİK O-RİNGİ 07000-15170',
    'MOTOR YAĞ FİLTRESİ LF9070 / 40C5067',
    'MOTOR YAKIT FİLTRESİ FF63010 / 40C9582',
    'MOTOR SU AYIRICI FİLTRESİ 53C2328 / FS53075',
    'MOTOR SU AYIRICI FİLTRESİ FS19765 / 40C9582',
    'MOTOR HAVA FİLTRESİ TAKIM 60C7942 / AF4403-AF4404',
    'HİDROLİK DÖNÜŞ FİLTRESİ 53C2061',
    'HİDROLİK EMİŞ FİLTRESİ 53C1487',
    'HİDROLİK PİLOT DÖNÜŞ FİLTRESİ 53C2423',
    'HİDROLİK PİLOT FİLTRESİ 53C0083',
    'KLİMA FİLTRESİ İÇ 46C6765',
    'KLİMA FİLTRESİ DIŞ 35C0827',
    'ADD BLUE TANK FİLTRE İÇ 53C1732',
    'ADD BLUE POMPA FİLTRESİ 37C1370',
    'FİLTRE ADBLUE POMP. SYUF 106-B SANY',
    'FİLTRE DEF.TANK SY160599000254A SANY',
    'FİLTRE HAVA DIŞ SYB222100000641-C SANY',
    'FİLTRE HAVA İÇ SYB222100000640-C SANY',
    'FİLTRE HİD.TNK.DNŞ SYGLQ008449764 SANY',
    'FİLTRE TNK EMŞ SÜZGC SY151502000062A SAN',
    'FİLTRE HİD.TNK.HVL. SY60186788 SANY',
    'FİLTRE KLİMA DIŞ SY141502000438B SANY',
    'FİLTRE KLİMA İÇ SYGLQ008359502 SANY',
    'FİLTRE KULE DNŞ.HAT SYGLQ008471460 SANY',
    'FİLTRE MOTOR YAĞ SYLF14009NN-B SANY',
    'FİLTRE PİLOT HAT SYGLQ009244827 SANY',
    'FİLTRE ŞASE YAKIT SYFS20121-B SANY',
    'FİLTRE YAKIT ANA SYFF63054NN-B SANY',
    'MOTOR YAĞ F 1R0739 CAT 140M',
    'YAKIT F 1R0762 CAT-140M',
    'HİDROLİK ATOM F 3283655 3283655 CAT-140M',
    'HAVA DIŞ MOTOR 2456375 CAT-140M',
    'HAVA İÇ MOTOR 2456376 CAT-140M',
    'SU - ŞASE F 3261644 CAT 140M',
    'HİDROLİK ELEMENT F FILTR 1R1809',
    'KLİMA KABİN F 1491912 CAT 140',
    'KABİN KLİMA F 2112660 CAT 140',
    'ŞANZUMAN F 1G8878',
    'AKH 8156 DIŞ HAVA FİLT. MG-530 HP 4017',
    'ME 056670-FF 5367 MAZOT FİL.MG-530',
    'AKY 8026-LF 3447 MOT.YAĞ FİL MG-530',
    'AF 976-35004-1 İÇ HAVA FİL MG 530',
    '58822-27400 FİLTRE MG-530',
    '34740-00100-LF 3382 ŞAN.YAĞ FİL MG530',
    'AKY 8024-LF 3432 BYPASS YAĞ FİL MG 530',
    '92576-14100 AKY 8846 HİDROLİK FİL. MG530',
    'SU F 12565210-WF 2075 BW 5075',
    'HAVA DIŞ MOTOR 1W2516-HP 798',
    'HİDROLİK F 7J670 AKY 8314',
    'ŞANZUMAN F 1R0719 - HF 06097',
    'MOTOR YAĞ F 2P4005 SP425 LF 6910',
    'HAVA İÇ MOTOR 7N1308 - AF 874',
    'YAKIT F 4377880-FS 1000',
    'KLİMA FİLTRESİ UZUN',
    'HAVA DIŞ MOTOR 7W9853 AF 4692',
    'HAVA İÇ MOTOR 7W9567 AF 4694',
    'HİDROLİK F 1R735 (AKY8385)',
    'HAVA DIŞ MOTOR AF 25129 DIŞ HAVA FİLT. 2653207478 (T35)',
    'HAVA İÇ MOTOR 2653207460 - AF 25130 MOTOR İÇ FİLT T 35',
    'HAVA DIŞ KOMP P812924 KOMP.DIŞ HAVA Fİ AF 25957 - T35',
    'HAVA İÇ KOMP 2653207387 KOMP İÇ HAVA FİLT.(T35)',
    'HİDROLİK F HİDROLİK FİLTRE 53096434 ATLAS 580',
    'KLİMA KABİN F 5118641970 KABİN FİLT. ATLAS T 35',
    'KOMP YAĞ F 36897353 KOMPRES. YAĞ FİLT. ATLAS 580',
    'SU AYIRICI FİLTRESİ 2657828816 SU AYR.FİLT. (T 35) FS 19732',
    'TOZ-KARTUJ F 2653254470 FİLTER CARTRIDGE - T 35',
    'YAKIT F FF 5421 3978040',
    'SEPERATÖR - ELEMENT 22402358 ELEMENT - SEPERATÖR ATLAS',
    'SEPERATÖR YAĞ FİLTRESİ ( T35)',
    'MOTOR YAĞ F N0281700381 LF 3970 HT 12059196',
    '3222 1881 31/001-AIR FILTER X 1 3222 1881 41/001-HAVA FİL.İÇ-DIŞ KOMP',
    '3222 1881 41/001-AIR FILTER X 1 3222 1881 31/001HAVA FİLTRE İÇ-DIŞ MOTOR',
    '3222 3456 25/001-BREATHER FILTER X 2 3222 3456 25 BREATHER FILT',
    '3222 3253 76/001-FILTER X 1 3222 3253 76/001',
    '3222 3253 78/001-FILTER X 1 3222 3253 78/001',
    '3222 3320 81/002-FILTER ELEMENT X 11',
    '3216 9214 04/001-OIL FILTER X 1',
    '3222 3252 97/001-OIL FILTER X 1',
    '3222 3476 44/001-FUEL FILTER X 1',
    '3222 9861 46/001-AIR FILTER X 1',
    '3222 3246 42/001-FILTER X 1',
    '3222 3362 53/001-FUEL FILTER X 2',
  ];

  /// [vehicle] için tanımlı filtre seçeneklerini döndürür.
  static List<String> filtersFor(Vehicle vehicle) => filtersForCode(vehicle.code);

  /// [vehicleCode] (örn. 'Euclid-1', 'XCMG-13', 'Komatsu-K6') için geçerli filtreleri döndürür.
  static List<String> filtersForCode(String vehicleCode) {
    final String c = vehicleCode.trim().toLowerCase();

    // Euclid 1..8
    for (int i = 1; i <= 8; i++) {
      if (c == 'euclid-$i' || c.contains('euclid.$i') || c.contains('euclid $i')) {
        if (i == 1) {
          return <String>[..._filtersGroup1, ..._filtersGroup2];
        }
        return _filtersGroup2;
      }
    }

    // Euclid 9..12
    for (int i = 9; i <= 12; i++) {
      if (c == 'euclid-$i' || c.contains('euclid.$i') || c.contains('euclid $i') || c.contains('htc.euc.$i')) {
        return _filtersGroup3;
      }
    }

    // XCMG 13..15
    for (int i = 13; i <= 15; i++) {
      if (c == 'xcmg-$i' || c.contains('xcmg.$i') || c.contains('xcmg $i') || c.contains('xcmg.e.$i')) {
        return _filtersGroup4;
      }
    }

    // Liugong Elektrikli Kamyonlar 16..20
    for (int i = 16; i <= 20; i++) {
      if (c == 'liugong-$i' || c.contains('liugong.$i') || c.contains('liugong $i') || c.contains('liugong_el_$i')) {
        return _filtersGroup5;
      }
    }

    // Liugong Elektrikli Loderler 33..37
    for (int i = 33; i <= 37; i++) {
      if (c == 'liugong-$i' || c.contains('liugong.$i') || c.contains('liugong $i') || c.contains('liug.el.$i')) {
        return _filtersGroup9;
      }
    }

    // Liugong Elektrikli Loderler 38..41 (38, 39 tekerlekli; 40, 41 paletli)
    for (int i = 38; i <= 41; i++) {
      if (c == 'liugong-$i' || c.contains('liugong.$i') || c.contains('liugong $i') || c.contains('liug.el.$i')) {
        return _filtersGroup10;
      }
    }

    // Liugong Paletli Ekskavatörler 6, 7
    if (c == 'liugong-6' || c == 'liugong-7' || c.contains('liugong 6') || c.contains('liugong 7')) {
      return _filtersGroup21;
    }

    // Hitachi 1200 / 1800 / 1900
    if (c.contains('1200')) {
      return _filtersGroup13;
    }
    if (c.contains('1800')) {
      return _filtersGroup14;
    }
    if (c.contains('1900')) {
      return _filtersGroup15;
    }

    // Hitachi 490 (490-1, 490-2)
    if (c.contains('490')) {
      return _filtersGroup12;
    }

    // Hitachi 350
    if (c.contains('350')) {
      return _filtersGroup11;
    }

    // Sany 68..70
    for (int i = 68; i <= 70; i++) {
      if (c == 'sany-$i' || c.contains('sany.$i') || c.contains('sany $i') || c.contains('sy.385h.$i') || c.contains('$i')) {
        if (c.contains('sany') || c.contains('sy')) {
          return _filtersGroup22;
        }
      }
    }
    if (c.contains('sany') || c.contains('385h')) {
      return _filtersGroup22;
    }

    // Komatsu 4, 5 (850 serisi)
    if (c == 'komatsu-4' || c == 'komatsu-5' || c.contains('komatsu 4') || c.contains('komatsu 5') || c.contains('komt.850')) {
      return _filtersGroup18;
    }

    // Komatsu K6, K7, K8 (550 serisi)
    if (c == 'komatsu-k6' || c == 'komatsu-k7' || c == 'komatsu-k8' || c.contains('komatsu 6') || c.contains('komatsu 7') || c.contains('komatsu 8') || c.contains('komt.550')) {
      return _filtersGroup19;
    }

    // Komatsu 450
    if (c.contains('450')) {
      return <String>[..._filtersGroup16, ..._filtersGroup17];
    }

    // Komatsu 390
    if (c.contains('390')) {
      return _filtersGroup20;
    }

    // Cat 140M Greyder
    if (c.contains('cater.grey') || c.contains('cat 140') || c.contains('140m')) {
      return <String>[..._filtersGroup23, ..._filtersGroup24];
    }

    // Mitsubishi Greyder
    if (c.contains('mitsu') || c.contains('mg-530') || c.contains('530')) {
      return _filtersGroup25;
    }

    // Cat D9L Dozer
    if (c.contains('d9l') || c.contains('d9')) {
      return _filtersGroup26;
    }

    // Cat D10N Dozer
    if (c.contains('d10n') || c.contains('d10')) {
      return _filtersGroup27;
    }

    // Atlas T35 Delici
    if (c.contains('atlas') || c.contains('t35') || c.contains('t-35')) {
      return <String>[..._filtersGroup28, ..._filtersGroup29, ..._filtersGroup30];
    }

    // Hitachi 310 Loder
    if (c.contains('htc.31') || c.contains('zw310') || c.contains('zw 310')) {
      return _filtersGroup6;
    }

    // Kawasaki 135 Loder
    if (c.contains('kawsk') || c.contains('kawasaki') || c.contains('135')) {
      return _filtersGroup7;
    }

    // Volvo L-180 Loder
    if (c.contains('vol29') || c.contains('volvo') || c.contains('l-180') || c.contains('l180')) {
      return _filtersGroup8;
    }

    // Tanımlı araç listesinde yoksa tüm filtreleri döndür
    return allFilters;
  }
}
