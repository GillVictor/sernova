import '../../../core/format/money.dart';
import '../../../core/l10n/strings.dart';
import '../domain/enums.dart';

/// "4,8" (French decimal comma).
String formatRating(double r) => r.toStringAsFixed(1).replaceAll('.', ',');

class PriceDisplay {
  const PriceDisplay({this.caption, required this.text});
  final String? caption; // small line above the amount
  final String text;
}

/// Price label from the pricing mode (Fixe, Horaire, SurDevis), OP-22.
PriceDisplay priceDisplay(PricingMode mode, Money? price) {
  if (mode == PricingMode.onQuote || price == null) {
    return PriceDisplay(text: Strings.t('search.offer.pricing.onQuote'));
  }
  return switch (mode) {
    PricingMode.hourly => PriceDisplay(
        caption: Strings.t('search.offer.pricing.hourly'),
        text: '${price.format()} ${Strings.t('search.offer.perHour')}',
      ),
    PricingMode.fixed => PriceDisplay(
        caption: Strings.t('search.offer.pricing.fixed'),
        text: price.format(),
      ),
    _ => PriceDisplay(
        caption: Strings.t('search.offer.pricing.unknown'),
        text: price.format(),
      ),
  };
}

/// Null for an unknown modality (shows nothing rather than a wrong label).
String? modalityLabel(Modality m) => switch (m) {
      Modality.remote => Strings.t('detail.modality.remote'),
      Modality.atHome => Strings.t('detail.modality.atHome'),
      Modality.onSite => Strings.t('detail.modality.onSite'),
      Modality.unknown => null,
    };

/// "98% de prestations achevées", or null when the rate is unknown.
String? completionLabel(double? rate) {
  if (rate == null) return null;
  final percent = rate.clamp(0.0, 100.0).round();
  return Strings.t('detail.completion', params: {'percent': percent});
}
