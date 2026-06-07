import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../inventory/data/providers/item_form_provider.dart';
import '../../data/providers/dashboard_provider.dart';
import '../../data/providers/low_stock_provider.dart';
import '../../data/providers/new_orders_provider.dart';
import '../../../reports/data/providers/report_providers.dart';
import '../widgets/greeting_header.dart';
import '../widgets/low_stock_alert.dart';
import '../widgets/new_orders_section.dart';
import '../widgets/omset_card.dart';
import '../widgets/profit_card.dart';
import '../widgets/transaction_count_card.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/top_selling_card.dart';

/// Dashboard screen — main home screen.
///
/// Kasir sees a slimmed view: greeting + omset + transaction count.
/// Profit, online orders, low-stock alerts, and top-selling analytics are
/// owner-only.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    ref.invalidate(dashboardProvider);
    ref.invalidate(lowStockProvider);
    ref.read(newOrdersProvider.notifier).refresh();
    ref.invalidate(topSellingItemsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final isOwner = ref.watch(isOwnerProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        user?.userMetadata?['display_name'] ??
        user?.userMetadata?['name'] ??
        'Admin';

    ref.listen<ItemFormState>(itemFormNotifierProvider, (previous, next) {
      if (previous?.isSuccess != true && next.isSuccess) {
        debugPrint(
          '[DASHBOARD] Item form success detected - auto-refreshing data',
        );
        _refreshData();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(dashboardProvider.notifier).refresh(),
            // NewOrdersSection now visible to kasir too — refresh for both.
            ref.read(newOrdersProvider.notifier).refresh(),
            if (isOwner) ref.read(lowStockProvider.notifier).refresh(),
            if (isOwner) ref.refresh(topSellingItemsProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GreetingHeader(name: displayName),
              const SizedBox(height: AppSpacing.lg),

              dashboardAsync.when(
                data: (summary) => Column(
                  children: [
                    if (isOwner) ...[
                      Row(
                        children: [
                          Expanded(child: OmsetCard(omset: summary.omset)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: ProfitCard(profit: summary.profit)),
                        ],
                      ),
                    ] else ...[
                      // Kasir view: omset stretches full width (no profit
                      // alongside — profit is owner-only). SizedBox forces
                      // Card to fill the available width, matching the
                      // transaction count card below.
                      SizedBox(
                        width: double.infinity,
                        child: OmsetCard(omset: summary.omset),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    TransactionCountCard(count: summary.transactionCount),
                    const SizedBox(height: AppSpacing.md),
                    OrderSummaryCard(
                      orderCount: summary.orderCount,
                      orderOmset: summary.orderOmset,
                    ),
                  ],
                ),
                loading: () => _buildShimmerCards(isOwner: isOwner),
                error: (error, _) => _buildErrorWidget(error),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Pesanan Baru — visible for both roles; kasir handles online
              // orders alongside owner.
              const NewOrdersSection(),
              const SizedBox(height: AppSpacing.lg),

              // Inventory and analytics remain owner-only.
              if (isOwner) ...[
                const LowStockAlert(),
                const SizedBox(height: AppSpacing.lg),
                const TopSellingCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCards({required bool isOwner}) {
    return Column(
      children: [
        if (isOwner)
          Row(
            children: [
              Expanded(child: _ShimmerCard()),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _ShimmerCard()),
            ],
          )
        else
          _ShimmerCard(),
        const SizedBox(height: AppSpacing.md),
        _ShimmerCard(),
        const SizedBox(height: AppSpacing.md),
        _ShimmerCard(),
      ],
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Gagal memuat data. Tarik ke bawah untuk coba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 14,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              height: 20,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
