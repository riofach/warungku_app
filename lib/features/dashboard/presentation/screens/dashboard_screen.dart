import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/providers/dashboard_provider.dart';
import '../widgets/greeting_header.dart';
import '../widgets/omset_card.dart';
import '../widgets/profit_card.dart';
import '../widgets/transaction_count_card.dart';

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
    // Auto-refresh dashboard data when screen is entered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(dashboardProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        user?.userMetadata?['display_name'] ?? user?.userMetadata?['name'] ?? 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
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

              // Placeholder sections (Story 5.2)
              Text(
                'Stok Menipis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Text(
                      '✅ Semua stok aman!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ),
              ),
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
