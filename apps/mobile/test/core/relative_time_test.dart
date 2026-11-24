import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/format/relative_time.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  final now = DateTime.utc(2026, 11, 21, 12);

  test('French relative times', () {
    expect(relativeTime(now, now.subtract(const Duration(seconds: 20))), "à l'instant");
    expect(relativeTime(now, now.subtract(const Duration(minutes: 5))), 'il y a 5 min');
    expect(relativeTime(now, now.subtract(const Duration(hours: 1))), 'il y a 1 h');
    expect(relativeTime(now, now.subtract(const Duration(days: 3))), 'il y a 3 j');
  });

  test('older than 30 days falls back to a date', () {
    final then = DateTime.utc(2026, 9, 1, 12);
    expect(relativeTime(now, then), '01/09/2026');
  });
}
