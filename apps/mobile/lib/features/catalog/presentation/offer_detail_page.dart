import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../data/catalog_repository.dart';
import '../domain/offer_models.dart';
import 'catalog_format.dart';
import 'offer_detail_controller.dart';
import 'widgets/expandable_text.dart';
import 'widgets/photo_gallery.dart';

/// Offer detail (use case UC04, EP-037). Public: no sign-in needed to read.
///
/// Not shown, on purpose: share and favorite buttons (no contract route, OP-20)
/// and the delivery-time chip of the mockup (no such field, OP-23).
class OfferDetailPage extends StatefulWidget {
  const OfferDetailPage({
    super.key,
    required this.repository,
    required this.offerId,
    this.onOpenProvider,
    this.onOrder,
  });

  final CatalogRepository repository;
  final String offerId;

  /// Public provider profile (EP-019), next task. Button hidden while null.
  final void Function(ProviderSummary provider)? onOpenProvider;

  /// Order flow (EP-051, tranche S3). Button hidden while null.
  final void Function(OfferDetail detail)? onOrder;

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  late final OfferDetailController _c =
      OfferDetailController(repository: widget.repository, offerId: widget.offerId);

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final d = _c.detail;
        final ready = _c.status == DetailStatus.ready && d != null;
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: ready
              ? null
              : AppBar(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                ),
          body: SafeArea(child: ready ? _Content(detail: d!, page: widget) : _State(c: _c)),
          bottomNavigationBar: ready && widget.onOrder != null
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
                      onPressed: () => widget.onOrder!(d!),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: Text(Strings.t('detail.order')),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _State extends StatelessWidget {
  const _State({required this.c});
  final OfferDetailController c;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (c.status == DetailStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final notFound = c.status == DetailStatus.notFound;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(notFound ? Icons.search_off : Icons.cloud_off, size: 56, color: AppColors.muted),
          const SizedBox(height: 16),
          Text(
            Strings.t(notFound ? 'detail.notFound.title' : 'detail.error.title'),
            textAlign: TextAlign.center,
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            notFound
                ? Strings.t('detail.notFound.subtitle')
                : Strings.error(c.failure?.code ?? 'UNKNOWN',
                    retryAfterSeconds: c.failure?.retryAfterSeconds),
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          if (!notFound) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: c.load, child: Text(Strings.t('common.retry'))),
          ],
        ]),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.detail, required this.page});
  final OfferDetail detail;
  final OfferDetailPage page;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final offer = detail.offer;
    final provider = detail.provider;
    final verified = provider.level.showsVerifiedBadge;
    final price = priceDisplay(offer.pricingMode, offer.price);
    final modality = modalityLabel(offer.modality);
    final location = provider.locationLabel;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Stack(children: [
          PhotoGallery(urls: detail.gallery),
          if (Navigator.of(context).canPop())
            Positioned(
              top: 12,
              left: 12,
              child: Material(
                color: AppColors.surface,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: Strings.t('common.back'),
                  icon: const Icon(Icons.arrow_back, color: AppColors.navy),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 20),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(offer.title,
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.25)),
          ),
          if (verified)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Tooltip(
                message: Strings.t('search.offer.verified'),
                child: const Icon(Icons.verified, color: AppColors.verified, size: 26),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        _RatingLine(rating: provider.rating, count: provider.reviewCount),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text.rich(TextSpan(children: [
            if (price.caption != null)
              TextSpan(
                text: '${price.caption} ',
                style: t.titleSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            TextSpan(
              text: price.text,
              style: t.headlineSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
            ),
          ])),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: [
          if (location != null) _Chip(icon: Icons.place, label: location),
          if (modality != null) _Chip(icon: Icons.schedule, label: modality),
          if (verified)
            _Chip(
              icon: Icons.check_circle,
              label: Strings.t('search.offer.verified'),
              color: AppColors.success,
              background: AppColors.successBg,
            ),
        ]),
        if (detail.description.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(Strings.t('detail.description'),
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ExpandableText(
            detail.description,
            style: t.bodyLarge?.copyWith(color: AppColors.muted, height: 1.5),
          ),
        ],
        if (detail.items.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(Strings.t('detail.items'),
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final item in detail.items) _ItemRow(item: item),
        ],
        const SizedBox(height: 24),
        Text(Strings.t('detail.provider'),
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _ProviderBlock(provider: provider, verified: verified, onOpen: page.onOpenProvider),
      ],
    );
  }
}

class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.rating, required this.count});
  final double? rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (rating == null || count == 0) {
      return Text(Strings.t('search.offer.noReviews'),
          style: t.bodyLarge?.copyWith(color: AppColors.muted));
    }
    return Row(children: [
      const Icon(Icons.star, color: AppColors.star, size: 22),
      const SizedBox(width: 6),
      Text(formatRating(rating!), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(width: 6),
      Text('(${Strings.t('search.offer.reviews', params: {'count': count})})',
          style: t.titleMedium?.copyWith(color: AppColors.muted)),
    ]);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
    this.background = AppColors.tint,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final OfferItem item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = !item.available;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
          child: Text(item.designation,
              style: t.bodyLarge?.copyWith(color: muted ? AppColors.muted : AppColors.ink)),
        ),
        if (muted)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(Strings.t('detail.itemUnavailable'),
                style: t.labelMedium?.copyWith(color: AppColors.danger)),
          ),
        if (item.price != null)
          Text(item.price!.format(),
              style: t.titleSmall?.copyWith(
                  color: muted ? AppColors.muted : AppColors.primary,
                  fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _ProviderBlock extends StatelessWidget {
  const _ProviderBlock({required this.provider, required this.verified, this.onOpen});
  final ProviderSummary provider;
  final bool verified;
  final void Function(ProviderSummary)? onOpen;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final completion = completionLabel(provider.completionRate);
    final avatar = provider.avatarUrl;
    final placeholder = Container(
      color: AppColors.iconBubble,
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 44, color: AppColors.muted),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        ClipOval(
          child: SizedBox(
            width: 84,
            height: 84,
            child: avatar == null
                ? placeholder
                : Image.network(avatar, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(provider.businessName,
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ),
              if (verified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: AppColors.verified, size: 22),
              ],
            ]),
            const SizedBox(height: 4),
            _RatingLine(rating: provider.rating, count: provider.reviewCount),
            if (completion != null) ...[
              const SizedBox(height: 4),
              Text(completion, style: t.bodyMedium?.copyWith(color: AppColors.muted)),
            ],
          ]),
        ),
      ]),
      if (onOpen != null) ...[
        const SizedBox(height: 16),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: const StadiumBorder(),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border, width: 1.5),
            textStyle: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          onPressed: () => onOpen!(provider),
          child: Text(Strings.t('detail.viewProfile')),
        ),
      ],
    ]);
  }
}
