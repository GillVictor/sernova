import '../l10n/strings.dart';

/// "il y a 1 h". The clock is passed in (never DateTime.now() inside logic).
String relativeTime(DateTime now, DateTime then) {
  final d = now.difference(then);
  if (d.inMinutes < 1) return Strings.t('time.now');
  if (d.inMinutes < 60) return Strings.t('time.minutes', params: {'n': d.inMinutes});
  if (d.inHours < 24) return Strings.t('time.hours', params: {'n': d.inHours});
  if (d.inDays < 30) return Strings.t('time.days', params: {'n': d.inDays});
  String two(int n) => n.toString().padLeft(2, '0');
  final l = then.toLocal();
  return '${two(l.day)}/${two(l.month)}/${l.year}';
}
