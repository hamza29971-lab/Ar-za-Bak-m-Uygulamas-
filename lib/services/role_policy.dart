import '../config/app_config.dart';
import '../models/models.dart';

/// Uygulamaya kimlerin girebileceğine karar verir: yalnızca
/// "Atölye Bakım Personeli" türündeki roller.
class RolePolicy {
  RolePolicy._();

  /// Kullanıcı gövdesine ([userJson], mining-be `userData`) göre karar verir.
  ///
  ///  1. Gövdenin herhangi bir yerinde izin verilen rol türü geçiyorsa
  ///     (ör. `role.type`, `role.group.name`) kabul edilir. Bu türe sonradan
  ///     eklenen roller de böylece kod değişmeden girer.
  ///  2. Tür bilgisi yoksa rol adı bilinen atölye rollerinden biriyse kabul
  ///     edilir.
  ///
  /// Hiçbiri tutmazsa reddedilir.
  static bool canUseApp(
    Map<String, dynamic> userJson, {
    List<String> allowedTypes = AppConfig.allowedRoleTypes,
    List<String> allowedRoles = AppConfig.workshopRoles,
  }) =>
      matchedRule(userJson, allowedTypes: allowedTypes, allowedRoles: allowedRoles) != null;

  /// Kararın gerekçesi (log için); reddedilirse `null`.
  static String? matchedRule(
    Map<String, dynamic> userJson, {
    List<String> allowedTypes = AppConfig.allowedRoleTypes,
    List<String> allowedRoles = AppConfig.workshopRoles,
  }) {
    final Set<String> types = allowedTypes.map(normalize).toSet();
    final String? path = _findValue(userJson, types, 'userData', 0);
    if (path != null) return 'rol türü ($path)';

    final String role = normalize(UserProfile.roleFromJson(userJson));
    if (role.isNotEmpty && allowedRoles.map(normalize).contains(role)) {
      return 'bilinen atölye rolü';
    }
    return null;
  }

  /// [targets]'tan birine eşit bir metin değerinin yolunu döndürür.
  static String? _findValue(Object? node, Set<String> targets, String path, int depth) {
    if (depth > 6) return null;
    if (node is String) return targets.contains(normalize(node)) ? path : null;
    if (node is Map) {
      for (final MapEntry<dynamic, dynamic> e in node.entries) {
        final String? hit = _findValue(e.value, targets, '$path.${e.key}', depth + 1);
        if (hit != null) return hit;
      }
    } else if (node is List) {
      for (int i = 0; i < node.length; i++) {
        final String? hit = _findValue(node[i], targets, '$path[$i]', depth + 1);
        if (hit != null) return hit;
      }
    }
    return null;
  }

  /// `"ATÖLYE BAKIM PERSONELİ"`, `"Atölye  Bakım Personeli"` ve
  /// `"atolye bakim personeli"` aynı anahtara iner. Dart'ın `toLowerCase`'i
  /// Türkçe `İ`/`I` harflerini doğru çevirmediği için önce elle eşlenir,
  /// ardından Türkçe karakterler Latin karşılıklarına indirgenir.
  static String normalize(String value) {
    final String lower = value
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase()
        .replaceAll('̇', '');
    const Map<String, String> fold = <String, String>{
      'ı': 'i',
      'ö': 'o',
      'ü': 'u',
      'ş': 's',
      'ç': 'c',
      'ğ': 'g',
    };
    final StringBuffer out = StringBuffer();
    for (final int rune in lower.runes) {
      final String ch = String.fromCharCode(rune);
      out.write(fold[ch] ?? ch);
    }
    return out.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
