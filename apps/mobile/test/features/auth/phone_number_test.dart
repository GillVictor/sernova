import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/features/auth/domain/phone_number.dart';

void main() {
  group('normalize', () {
    test('removes spaces, dashes, dots and parentheses typed inside the number', () {
      expect(PhoneNumber.normalize(' +242 06-123.45 (67) '), '+242061234567');
    });

    test('adds nothing and changes nothing else', () {
      expect(PhoneNumber.normalize('0612345678'), '0612345678');
      expect(PhoneNumber.normalize('+242abc'), '+242abc');
    });

    test('blank stays blank', () {
      expect(PhoneNumber.normalize('   '), '');
    });
  });

  group('isE164 (plus sign, then 7 to 15 digits, no leading zero)', () {
    test('accepts valid numbers', () {
      expect(PhoneNumber.isE164('+242061234567'), isTrue);
      expect(PhoneNumber.isE164('+221771234567'), isTrue);
    });

    for (final bad in const [
      '',
      '242061234567', // no plus sign
      '0612345678', // local number
      '+0123456789', // country code cannot start with 0
      '+24206', // too short
      '+2420612345678901', // 16 digits
      '+24206abc12345',
      '++242061234567',
    ]) {
      test('rejects "$bad"', () => expect(PhoneNumber.isE164(bad), isFalse));
    }
  });
}
