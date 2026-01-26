import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
import '../widgets/top_selling_card.dart';
import '../../../orders/data/models/order_model.dart';

/// Dashboard screen - main home screen for admin
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-refresh dashboard data when screen is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
    
    // Set notification callback
    NewOrdersNotifier.onNewOrderReceived = _handleNewOrderNotification;
  }
  
  @override
  void dispose() {
    // Clean up notification callback
    if (NewOrdersNotifier.onNewOrderReceived == _handleNewOrderNotification) {
      NewOrdersNotifier.onNewOrderReceived = null;
    }
    super.dispose();
  }
  
  void _handleNewOrderNotification(Order order) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pesanan Baru Diterima!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${order.customerName} - ${formatRupiah(order.total)} (Belum dibayar)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'LIHAT',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to orders screen or show detail
            // context.push('/orders');
          },
        ),
      ),
    );
  }

  /// Refresh dashboard and low stock data
  void _refreshData() {
    ref.invalidate(dashboardProvider);
    ref.invalidate(lowStockProvider);
    ref.invalidate(newOrdersProvider);
    ref.invalidate(topSellingItemsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        user?.userMetadata?['display_name'] ?? user?.userMetadata?['name'] ?? 'Admin';

    // Listen to item form state changes for real-time dashboard updates
    // When item is successfully updated/created, auto-refresh dashboard
    ref.listen<ItemFormState>(
      itemFormNotifierProvider,
      (previous, next) {
        // Only refresh if status changed from non-success to success
        // This prevents refresh on every build
        if (previous?.isSuccess != true && next.isSuccess) {
          debugPrint('[DASHBOARD] Item form success detected - auto-refreshing data');
          _refreshData();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(dashboardProvider.notifier).refresh(),
            ref.read(lowStockProvider.notifier).refresh(),
            ref.read(newOrdersProvider.notifier).refresh(),
            ref.refresh(topSellingItemsProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting header
              GreetingHeader(name: displayName),
              const SizedBox(height: AppSpacing.lg),

              // Summary cards
              dashboardAsync.when(
                data: (summary) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: OmsetCard(omset: summary.omset)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: ProfitCard(profit: summary.profit)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TransactionCountCard(count: summary.transactionCount),
                  ],
                ),
                loading: () => _buildShimmerCards(),
                error: (error, _) => _buildErrorWidget(error),
              ),
              const SizedBox(height: AppSpacing.lg),

              // New Orders Section (Story 5.3)
              const NewOrdersSection(),
              const SizedBox(height: AppSpacing.lg),

              // Low Stock Alert Section (Story 5.2)
              const LowStockAlert(),
              const SizedBox(height: AppSpacing.lg),

              // Top Selling Items (Story 5.4)
              const TopSellingCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ShimmerCard()),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _ShimmerCard()),
          ],
        ),
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
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
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
