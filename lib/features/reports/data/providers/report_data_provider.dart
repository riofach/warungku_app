import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/transactions/data/models/transaction_model.dart';
import '../../providers/report_filter_provider.dart';
import '../models/report_summary_model.dart';
import '../repositories/report_repository.dart';

// Repository Provider
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(Supabase.instance.client);
});

// Summary Provider (Revenue, Profit, Count)
final reportSummaryProvider = FutureProvider.autoDispose<ReportSummary>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);
  
  return repository.getReportSummary(filter.dateRange.start, filter.dateRange.end);
});

// Transactions List Provider
final reportTransactionsProvider = FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);
  
  return repository.getTransactions(filter.dateRange.start, filter.dateRange.end);
});
