import 'package:flutter/material.dart';

import '../../../core/api/load_state.dart';
import '../../../core/domain/count.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/format/relative_time.dart';
import '../../../core/theme/app_colors.dart';
import '../../account/data/account_repository.dart';
import '../../catalog/presentation/catalog_format.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/notification_models.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order_models.dart';
import '../../requests/data/request_feed_repository.dart';
import '../data/provider_repository.dart';
import 'dashboard_controller.dart';
import 'widgets/provider_header.dart';

/// Provider dashboard (mockup "Tableau de bord"). Needs a signed-in provider.
class ProviderDashboardPage extends StatefulWidget {
  const ProviderDashboardPage({
    super.key,
    required this.provider,
    required this.account,
    required this.orders,
    required this.requests,
    required this.notifications,
    this.now = DateTime.now,
    this.onOpenOrders,
    this.onOpenProfile,
  });

  final ProviderRepository provider;
  final AccountRepository account;
  final OrderRepository orders;
  final RequestFeedRepository requests;
  final NotificationRepository notifications;

  /// Injected clock (relative times).
  final DateTime Function() now;

  /// "Voir les commandes": orders list (S3). Button hidden while null.
  final VoidCallback? onOpenOrders;

  /// Avatar tap: "Mon profil professionnel".
  final VoidCallback? onOpenProfile;

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage> {
  late final DashboardController _c = DashboardController(
    provider: widget.provider,
    account: widget.account,
    orders: widget.orders,
    requests: widget.requests,
    notifications: widget.notifications,
  );
  final _notificationsKey = GlobalKey();

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

  void _scrollToNotifications() {
    final ctx = _notificationsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            final name = _c.account.data?.displayName;
            return Column(children: [
              ProviderHeader(
                initials: _c.account.data?.initials ?? '',
                unread: _c.unread,
                onBell: _scrollToNotifications,
                onAvatar: widget.onOpenProfile,
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _c.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(Strings.t('provider.dashboard.title'),
                                style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(Strings.t('provider.dashboard.subtitle'),
                                style: t.bodyLarge?.copyWith(color: AppColors.muted)),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        Flexible(child: RoleChip(displayName: name)),
                      ]),
                      const SizedBox(height: 20),
                      _Stats(c: _c),
                      const SizedBox(height: 20),
                      _OrdersCard(c: _c, onOpenOrders: widget.onOpenOrders),
                      const SizedBox(height: 20),
                      _NotificationsCard(key: _notificationsKey, c: _c, now: widget.now),
                    ],
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- stats

class _Stats extends StatelessWidget {
  const _Stats({required this.c});
  final DashboardController c;

  String _count(LoadState<Count> s) => s.isLoading
      ? '…'
      : s.hasFailed
          ? Strings.t('provider.dashboard.stats.unavailable')
          : s.data!.label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final profile = c.profile;
    final completion = profile.data?.completionRate;
    final rating = profile.data?.rating;
    final hasCount = c.inProgress.hasData && c.inProgress.data!.value > 0;

    String profileValue(String? v) => profile.isLoading
        ? '…'
        : (profile.hasFailed || v == null)
            ? Strings.t('provider.dashboard.stats.unavailable')
            : v;

    return Column(children: [
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: _StatCard(
            label: Strings.t('provider.dashboard.stats.inProgress.label'),
            value: _count(c.inProgress),
            color: AppColors.primary,
            tag: hasCount ? Strings.t('provider.dashboard.stats.inProgress.tag') : null,
            tagColor: AppColors.primary,
            tagBackground: AppColors.tint,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            label: Strings.t('provider.dashboard.stats.available.label'),
            value: _count(c.available),
            color: AppColors.primary,
            tag: (c.available.hasData && c.available.data!.value > 0)
                ? Strings.t('provider.dashboard.stats.available.tag')
                : null,
            tagColor: const Color(0xFF0B6E8A),
            tagBackground: const Color(0xFFE3F4F9),
          ),
        ),
      ])),
      const SizedBox(height: 14),
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: _StatCard(
            label: Strings.t('provider.dashboard.stats.completion.label'),
            value: profileValue(completion == null
                ? null
                : Strings.t('provider.dashboard.stats.percent',
                    params: {'n': completion.clamp(0, 100).round()})),
            color: AppColors.success,
            tag: completion == null ? null : Strings.t('provider.dashboard.stats.completion.tag'),
            tagColor: AppColors.success,
            tagBackground: AppColors.successBg,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            label: Strings.t('provider.dashboard.stats.rating.label'),
            value: profileValue(rating == null ? null : formatRating(rating)),
            color: const Color(0xFFF59E0B),
            suffix: rating == null ? null : Strings.t('provider.dashboard.stats.rating.outOf'),
            trailing: rating == null
                ? null
                : const Icon(Icons.star, color: Color(0xFFF59E0B), size: 26),
          ),
        ),
      ])),
      if (profile.hasFailed) ...[
        const SizedBox(height: 8),
        Text(Strings.error(profile.failure!.code, retryAfterSeconds: profile.failure!.retryAfterSeconds),
            style: t.bodySmall?.copyWith(color: AppColors.danger)),
      ],
    ]);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.tag,
    this.tagColor,
    this.tagBackground,
    this.suffix,
    this.trailing,
  });
  final String label;
  final String value;
  final Color color;
  final String? tag;
  final Color? tagColor;
  final Color? tagBackground;
  final String? suffix;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: t.titleSmall?.copyWith(color: AppColors.muted)),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(
            child: Text(value,
                style: t.headlineLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(suffix!, style: t.titleMedium?.copyWith(color: AppColors.muted)),
            ),
          ],
          const Spacer(),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: tagBackground, borderRadius: BorderRadius.circular(12)),
              child: Text(tag!,
                  style: t.labelLarge?.copyWith(color: tagColor, fontWeight: FontWeight.w700)),
            ),
          if (trailing != null) trailing!,
        ]),
      ]),
    );
  }
}

// --------------------------------------------------------------- shared

class _SectionCard extends StatelessWidget {
  const _SectionCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(Strings.t('provider.dashboard.sectionError'),
            style: const TextStyle(color: AppColors.muted)),
        TextButton(onPressed: onRetry, child: Text(Strings.t('common.retry'))),
      ]);
}

// --------------------------------------------------------------- orders

class _OrdersCard extends StatelessWidget {
  const _OrdersCard({required this.c, this.onOpenOrders});
  final DashboardController c;
  final VoidCallback? onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = c.recent;
    final items = s.data ?? const <OrderSummary>[];
    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.circle, size: 12, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(Strings.t('provider.dashboard.orders.title'),
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          if (s.hasData && items.isNotEmpty)
            Text(Strings.t('provider.dashboard.orders.recent', params: {'n': items.length}),
                style: t.bodyMedium?.copyWith(color: AppColors.muted)),
        ]),
        const SizedBox(height: 8),
        if (s.isLoading)
          const Padding(
              padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
        else if (s.hasFailed)
          Center(child: _SectionError(onRetry: c.load))
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(Strings.t('provider.dashboard.orders.empty'),
                  style: const TextStyle(color: AppColors.muted)),
            ),
          )
        else
          for (final o in items) _OrderRow(order: o),
        if (onOpenOrders != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: const StadiumBorder(),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              textStyle: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            onPressed: onOpenOrders,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(Strings.t('provider.dashboard.orders.viewAll')),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});
  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final style = orderStatusStyle(order.status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(children: [
              TextSpan(
                  text: '${order.reference}  ',
                  style: t.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
              TextSpan(text: order.title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ])),
            if (order.counterpartName != null && order.counterpartName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                  Strings.t('provider.dashboard.orders.client',
                      params: {'name': order.counterpartName!}),
                  style: t.bodyMedium?.copyWith(color: AppColors.muted)),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: style.border),
          ),
          child: Text(orderStatusLabel(order.status),
              style: t.labelLarge?.copyWith(color: style.foreground, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class OrderStatusStyle {
  const OrderStatusStyle(this.foreground, this.background, this.border);
  final Color foreground;
  final Color background;
  final Color border;
}

String orderStatusLabel(TransactionStatus s) => Strings.t(switch (s) {
      TransactionStatus.pending => 'provider.dashboard.orders.status.pending',
      TransactionStatus.accepted => 'provider.dashboard.orders.status.accepted',
      TransactionStatus.scheduled => 'provider.dashboard.orders.status.scheduled',
      TransactionStatus.inProgress => 'provider.dashboard.orders.status.inProgress',
      TransactionStatus.completed => 'provider.dashboard.orders.status.completed',
      TransactionStatus.confirmed => 'provider.dashboard.orders.status.confirmed',
      TransactionStatus.closed => 'provider.dashboard.orders.status.closed',
      TransactionStatus.cancelled => 'provider.dashboard.orders.status.cancelled',
      TransactionStatus.disputed => 'provider.dashboard.orders.status.disputed',
      TransactionStatus.unknown => 'provider.dashboard.orders.status.unknown',
    });

/// Colors of the status pill (mockup: amber, blue, green, grey).
OrderStatusStyle orderStatusStyle(TransactionStatus s) {
  const amber = OrderStatusStyle(Color(0xFFB45309), Color(0xFFFFF7E0), Color(0xFFF6D77A));
  const blue = OrderStatusStyle(AppColors.primary, AppColors.tint, Color(0xFFB9CCF4));
  const green = OrderStatusStyle(AppColors.success, AppColors.successBg, Color(0xFF9ADBC0));
  const grey = OrderStatusStyle(Color(0xFF475569), Color(0xFFF1F5F9), Color(0xFFCBD5E1));
  const red = OrderStatusStyle(AppColors.danger, Color(0xFFFDECEF), Color(0xFFF5B5C1));
  return switch (s) {
    TransactionStatus.pending => amber,
    TransactionStatus.inProgress || TransactionStatus.scheduled => blue,
    TransactionStatus.accepted || TransactionStatus.confirmed => green,
    TransactionStatus.disputed || TransactionStatus.cancelled => red,
    TransactionStatus.completed || TransactionStatus.closed || TransactionStatus.unknown => grey,
  };
}

// -------------------------------------------------------- notifications

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({super.key, required this.c, required this.now});
  final DashboardController c;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = c.notifications;
    final items = s.data?.items ?? const <AppNotification>[];
    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.notifications_none, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(Strings.t('provider.dashboard.notifications.title'),
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          if (c.unread > 0)
            TextButton(
              onPressed: c.markAllRead,
              child: Text(Strings.t('provider.dashboard.notifications.markAllRead'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ]),
        const Divider(color: AppColors.border),
        if (s.isLoading)
          const Padding(
              padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
        else if (s.hasFailed)
          Center(child: _SectionError(onRetry: c.load))
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(Strings.t('provider.dashboard.notifications.empty'),
                  style: const TextStyle(color: AppColors.muted)),
            ),
          )
        else
          for (final n in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: n.read ? null : () => c.markRead(n.id),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 12),
                      child: Icon(Icons.circle,
                          size: 12, color: n.read ? AppColors.border : AppColors.primary),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.content,
                            style: t.titleMedium?.copyWith(
                                fontWeight: n.read ? FontWeight.w500 : FontWeight.w700)),
                        if (n.createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(relativeTime(now(), n.createdAt!),
                              style: t.bodyMedium?.copyWith(color: AppColors.muted)),
                        ],
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
      ]),
    );
  }
}