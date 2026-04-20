import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/transaction_model.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(transaction.code),
        actions: [
          _PaymentMethodBadge(method: transaction.paymentMethod),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _InfoCard(
            children: [
              _DetailRow(
                icon: Icons.person_outline,
                label: 'Diproses oleh',
                value: transaction.adminName,
              ),
              _DetailRow(
                icon: Icons.access_time,
                label: 'Waktu',
                value: transaction.formattedDate,
              ),
              if (transaction.isCash) ...[
                _DetailRow(
                  icon: Icons.payments_outlined,
                  label: 'Uang diterima',
                  value: transaction.formattedCashReceived,
                ),
                _DetailRow(
                  icon: Icons.change_circle_outlined,
                  label: 'Kembalian',
                  value: transaction.formattedChange,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoCard(
            title: 'Item',
            children: transaction.items.isEmpty
                ? [
                    Text(
                      'Detail item tidak tersedia',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ]
                : transaction.items
                    .map((item) => _ItemRow(item: item))
                    .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    transaction.formattedTotal,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _InfoCard({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodBadge extends StatelessWidget {
  final String method;

  const _PaymentMethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    final isQris = method == 'qris';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isQris
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isQris ? Icons.qr_code : Icons.payments_outlined,
            size: 14,
            color: isQris ? AppColors.primary : AppColors.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            isQris ? 'QRIS' : 'Tunai',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isQris ? AppColors.primary : AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final TransactionItem item;

  const _ItemRow({required this.item});

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName ?? item.itemId ?? 'Item',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${item.quantity} x ${_formatCurrency(item.price)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(item.subtotal),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
