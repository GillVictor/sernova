import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/offer_models.dart';
import '../catalog_format.dart';

/// Result card of the search list (mockup "Plomberie").
/// No favorite heart: no route exists for it in the contract (OP-20).
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.item, this.onTap});

  final OfferSearchItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final offer = item.offer;
    final provider = item.provider;
    final location = provider.locationLabel;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Photo(url: offer.photoUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(
                          offer.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (provider.level.showsVerifiedBadge) ...[
                        const SizedBox(width: 6),
                        Tooltip(
                          message: Strings.t('search.offer.verified'),
                          child: const Icon(Icons.verified, size: 20, color: AppColors.verified),
                        ),
                      ],
                    ]),
                    if (offer.categoryName != null) ...[
                      const SizedBox(height: 4),
                      _IconLine(
                        icon: Icons.build_outlined,
                        child: Text(offer.categoryName!,
                            style: t.bodyMedium?.copyWith(color: AppColors.muted)),
                      ),
                    ],
                    const SizedBox(height: 4),
                    _Rating(rating: provider.rating, count: provider.reviewCount),
                    if (location != null) ...[
                      const SizedBox(height: 4),
                      _IconLine(
                        icon: Icons.place_outlined,
                        child: Text(
                          _withDistance(location, item.distanceKm),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium?.copyWith(color: AppColors.muted),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: _Price(offer: offer)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _withDistance(String location, double? km) {
  if (km == null) return location;
  final away = Strings.t('search.offer.away',
      params: {'km': km.toStringAsFixed(1).replaceAll('.', ',')});
  return '$location · $away';
}

class _Photo extends StatelessWidget {
  const _Photo({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.iconBubble,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: AppColors.muted, size: 32),
    );
    return Semantics(
      label: url == null ? Strings.t('search.offer.noPhoto') : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 104,
          height: 104,
          child: url == null
              ? placeholder
              : Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => placeholder,
                ),
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.child});
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 6),
        Flexible(child: child),
      ]);
}

class _Rating extends StatelessWidget {
  const _Rating({required this.rating, required this.count});
  final double? rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (rating == null || count == 0) {
      return Text(Strings.t('search.offer.noReviews'),
          style: t.bodyMedium?.copyWith(color: AppColors.muted));
    }
    return Row(children: [
      const Icon(Icons.star, size: 18, color: AppColors.star),
      const SizedBox(width: 4),
      Text(formatRating(rating!),
          style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(width: 4),
      Text('(${Strings.t('search.offer.reviews', params: {'count': count})})',
          style: t.bodyMedium?.copyWith(color: AppColors.muted)),
    ]);
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.offer});
  final OfferSummary offer;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = priceDisplay(offer.pricingMode, offer.price);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (p.caption != null)
          Text(p.caption!, style: t.bodySmall?.copyWith(color: AppColors.muted)),
        Text(
          p.text,
          style: t.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
