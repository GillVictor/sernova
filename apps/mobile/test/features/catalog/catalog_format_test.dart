import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/format/money.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/features/catalog/domain/enums.dart';
import 'package:servnova_mobile/features/catalog/presentation/catalog_format.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  const fifty = Money(amount: 50000, currency: 'XAF');

  test('price by pricing mode', () {
    final fixed = priceDisplay(PricingMode.fixed, fifty);
    expect(fixed.caption, 'Prix');
    expect(fixed.text, '50\u202F000\u00A0FCFA');

    expect(priceDisplay(PricingMode.hourly, fifty).text, '50\u202F000\u00A0FCFA / h');

    final quote = priceDisplay(PricingMode.onQuote, fifty);
    expect(quote.text, 'Sur devis');
    expect(quote.caption, isNull);

    expect(priceDisplay(PricingMode.fixed, null).text, 'Sur devis'); // no amount
  });

  test('rating, modality and completion labels', () {
    expect(formatRating(4.8), '4,8');
    expect(modalityLabel(Modality.remote), 'À distance');
    expect(modalityLabel(Modality.unknown), isNull);
    expect(completionLabel(98), '98% de prestations achevées');
    expect(completionLabel(140), '100% de prestations achevées'); // clamped
    expect(completionLabel(null), isNull);
  });
}
