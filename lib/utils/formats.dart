/// Küçük tarih/sayı biçimleyicileri (intl bağımlılığı olmadan).
library;

const List<String> _months = <String>[
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
  'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
];

const List<String> _weekdays = <String>[
  'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz',
];

String two(int n) => n.toString().padLeft(2, '0');

/// 17.08.2026
String formatDate(DateTime d) => '${two(d.day)}.${two(d.month)}.${d.year}';

/// 17 Ağu 2026
String formatLongDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// 17 Ağu 2026 Pzt
String formatFullDate(DateTime d) =>
    '${formatLongDate(d)} ${_weekdays[d.weekday - 1]}';

/// 11:41:53
String formatTime(DateTime d, {bool withSeconds = true}) => withSeconds
    ? '${two(d.hour)}:${two(d.minute)}:${two(d.second)}'
    : '${two(d.hour)}:${two(d.minute)}';

/// 17.08.2026 11:41
String formatDateTime(DateTime d) =>
    '${formatDate(d)} ${formatTime(d, withSeconds: false)}';

/// "3 sa önce", "dün", "2 gün önce"
String relativeTime(DateTime d) {
  final Duration diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'şimdi';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
  if (diff.inHours < 24) return '${diff.inHours} sa önce';
  if (diff.inDays == 1) return 'dün';
  if (diff.inDays < 30) return '${diff.inDays} gün önce';
  return formatDate(d);
}

/// Bir tarihin üzerinden geçen gün sayısı.
int daysSince(DateTime d) {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day)
      .difference(DateTime(d.year, d.month, d.day))
      .inDays;
}
