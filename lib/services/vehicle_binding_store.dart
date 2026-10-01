import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'vehicle_directory_service.dart';

/// Bir yerel aracın sunucudaki karşılığıyla kalıcı bağı.
///
/// Bağ bir kez kurulduktan sonra **kimlik UUID'dir**; sunucudaki isim
/// serbestçe değişebilir, bağ kopmaz. Eskiden eşleştirme her girişte
/// isimden yeniden hesaplandığı için sunucudaki bir yeniden adlandırma
/// bağı tamamen kaybettiriyordu.
@immutable
class VehicleBinding {
  const VehicleBinding({
    required this.localCode,
    required this.uuid,
    required this.serverLabel,
    this.missingSince,
  });

  /// Uygulamadaki araç kodu, ör. `Euclid-2`.
  final String localCode;

  /// Sunucudaki değişmez kimlik.
  final String uuid;

  /// Sunucuda en son görülen isim. Yalnızca bilgi amaçlıdır.
  final String serverLabel;

  /// Araç sunucu listesinde ilk kez ne zaman görünmez oldu?
  /// `null` ise araç yerinde demektir.
  final DateTime? missingSince;

  VehicleBinding copyWith({
    String? serverLabel,
    DateTime? missingSince,
    bool clearMissing = false,
  }) {
    return VehicleBinding(
      localCode: localCode,
      uuid: uuid,
      serverLabel: serverLabel ?? this.serverLabel,
      missingSince: clearMissing ? null : (missingSince ?? this.missingSince),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'localCode': localCode,
        'uuid': uuid,
        'serverLabel': serverLabel,
        if (missingSince != null) 'missingSince': missingSince!.toIso8601String(),
      };

  static VehicleBinding? fromJson(Map<String, Object?> json) {
    final String localCode = '${json['localCode'] ?? ''}'.trim();
    final String uuid = '${json['uuid'] ?? ''}'.trim();
    if (localCode.isEmpty || uuid.isEmpty) return null;
    final Object? missing = json['missingSince'];
    return VehicleBinding(
      localCode: localCode,
      uuid: uuid,
      serverLabel: '${json['serverLabel'] ?? ''}',
      missingSince: missing is String ? DateTime.tryParse(missing) : null,
    );
  }
}

/// Bir aracın sunucuda yeniden adlandırılması.
@immutable
class VehicleRename {
  const VehicleRename({
    required this.localCode,
    required this.from,
    required this.to,
  });

  final String localCode;
  final String from;
  final String to;
}

/// Dizin çekiminin sonucu. Ekranlar ve kayıtlar bunu okur.
@immutable
class VehicleDirectorySync {
  const VehicleDirectorySync({
    this.renamed = const <VehicleRename>[],
    this.newlyBound = const <String>[],
    this.missing = const <String>[],
    this.unmatched = const <String>[],
    this.serverOnly = const <String>[],
    this.fetchedAt,
  });

  /// UUID aynı kaldı ama sunucudaki isim değişti.
  final List<VehicleRename> renamed;

  /// Bu çekimde ilk kez bağlanan yerel araç kodları.
  final List<String> newlyBound;

  /// Bağlı ama sunucu listesinde görünmeyen araçlar.
  final List<String> missing;

  /// Hiç bağlanamamış yerel araç kodları.
  final List<String> unmatched;

  /// Sunucuda olup hiçbir yerel araca bağlanmayan isimler.
  final List<String> serverOnly;

  final DateTime? fetchedAt;

  bool get hasChanges =>
      renamed.isNotEmpty || newlyBound.isNotEmpty || missing.isNotEmpty;
}

/// Araç bağlarını saklayan ve sunucu dizini ile uzlaştıran depo.
class VehicleBindingStore {
  VehicleBindingStore({this.canonicalKey});

  static const String _prefsKey = 'vehicle_bindings_v1';

  /// İlk bağlamada kullanılan isim normalleştirmesi. [AppState] kendi
  /// marka/numara mantığını buraya verir.
  final String? Function(String label)? canonicalKey;

  final Map<String, VehicleBinding> _byLocalCode = <String, VehicleBinding>{};

  /// Son çekilen sunucu dizini. Henüz bağı olmayan bir kod sorulduğunda
  /// isimden çözmek için saklanır.
  List<VehicleDirectoryEntry> _lastEntries = const <VehicleDirectoryEntry>[];

  Map<String, VehicleBinding> get bindings =>
      Map<String, VehicleBinding>.unmodifiable(_byLocalCode);

  /// Araç koduna karşılık gelen UUID.
  ///
  /// Önce kalıcı bağa bakılır: bağ varsa sunucudaki isim değişmiş olsa bile
  /// doğru UUID döner. Bağ yoksa (ör. filoya yeni eklenmiş ya da hiç
  /// bağlanmamış bir kod) son dizin üzerinden isimle çözülmeye çalışılır.
  String? uuidFor(String localCode) {
    final String? bound = _byLocalCode[localCode]?.uuid;
    if (bound != null) return bound;

    final String? key = canonicalKey?.call(localCode);
    if (key == null) return null;
    for (final VehicleDirectoryEntry e in _lastEntries) {
      if (canonicalKey?.call(e.label) == key) return e.id;
    }
    return null;
  }

  /// Diskten yükler. Ağ olmasa bile bağlar elde kalsın diye açılışta çağrılır.
  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<Object?>) return;
      _byLocalCode.clear();
      for (final Object? item in decoded) {
        if (item is Map<String, Object?>) {
          final VehicleBinding? binding = VehicleBinding.fromJson(item);
          if (binding != null) _byLocalCode[binding.localCode] = binding;
        }
      }
    } on Object catch (e) {
      debugPrint('[VehicleBinding] yüklenemedi: $e');
    }
  }

  Future<void> save() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(<Object?>[
          for (final VehicleBinding b in _byLocalCode.values) b.toJson(),
        ]),
      );
    } on Object catch (e) {
      debugPrint('[VehicleBinding] kaydedilemedi: $e');
    }
  }

  /// Sunucu dizinini mevcut bağlarla uzlaştırır.
  ///
  /// Kurallar:
  ///  * Var olan bağ **asla silinmez**. Araç sunucu listesinde yoksa yalnızca
  ///    "kayıp" işaretlenir; sunucu geçici olarak eksik liste dönerse bağların
  ///    uçmaması için.
  ///  * İsim eşleştirmesi yalnızca **henüz bağlanmamış** araçlar için çalışır.
  ///    Bağlı araçlar UUID üzerinden takip edilir, isim değişikliği bağı
  ///    bozmaz; yalnızca kaydedilir.
  VehicleDirectorySync reconcile({
    required List<VehicleDirectoryEntry> entries,
    required List<String> localCodes,
    DateTime? now,
  }) {
    final DateTime stamp = now ?? DateTime.now();
    _lastEntries = List<VehicleDirectoryEntry>.unmodifiable(entries);
    final Map<String, VehicleDirectoryEntry> byUuid =
        <String, VehicleDirectoryEntry>{
      for (final VehicleDirectoryEntry e in entries) e.id: e,
    };

    final List<VehicleRename> renamed = <VehicleRename>[];
    final List<String> missing = <String>[];

    // 1) Mevcut bağları UUID üzerinden tazele.
    for (final VehicleBinding binding in _byLocalCode.values.toList()) {
      final VehicleDirectoryEntry? entry = byUuid[binding.uuid];
      if (entry == null) {
        if (binding.missingSince == null) {
          _byLocalCode[binding.localCode] =
              binding.copyWith(missingSince: stamp);
          missing.add(binding.localCode);
        }
        continue;
      }
      if (entry.label != binding.serverLabel) {
        renamed.add(VehicleRename(
          localCode: binding.localCode,
          from: binding.serverLabel,
          to: entry.label,
        ));
      }
      _byLocalCode[binding.localCode] =
          binding.copyWith(serverLabel: entry.label, clearMissing: true);
    }

    // 2) Henüz bağlanmamış yerel araçları isimden eşleştir.
    final Set<String> boundUuids =
        _byLocalCode.values.map((VehicleBinding b) => b.uuid).toSet();
    final List<String> newlyBound = <String>[];
    final List<String> unmatched = <String>[];

    for (final String code in localCodes) {
      if (_byLocalCode.containsKey(code)) continue;
      final String? key = canonicalKey?.call(code);
      VehicleDirectoryEntry? match;
      if (key != null) {
        for (final VehicleDirectoryEntry e in entries) {
          if (boundUuids.contains(e.id)) continue;
          if (canonicalKey?.call(e.label) == key) {
            match = e;
            break;
          }
        }
      }
      if (match == null) {
        unmatched.add(code);
        continue;
      }
      _byLocalCode[code] = VehicleBinding(
        localCode: code,
        uuid: match.id,
        serverLabel: match.label,
      );
      boundUuids.add(match.id);
      newlyBound.add(code);
    }

    // 3) Sunucuda olup hiçbir yerele bağlanmayanlar (bilgi amaçlı).
    final List<String> serverOnly = <String>[
      for (final VehicleDirectoryEntry e in entries)
        if (!boundUuids.contains(e.id)) e.label,
    ];

    return VehicleDirectorySync(
      renamed: renamed,
      newlyBound: newlyBound,
      missing: missing,
      unmatched: unmatched,
      serverOnly: serverOnly,
      fetchedAt: stamp,
    );
  }

  /// Testler için: ağ olmadan bağ kurar.
  @visibleForTesting
  void seed(Iterable<VehicleBinding> seeded) {
    _byLocalCode
      ..clear()
      ..addEntries(seeded.map(
        (VehicleBinding b) => MapEntry<String, VehicleBinding>(b.localCode, b),
      ));
  }
}
