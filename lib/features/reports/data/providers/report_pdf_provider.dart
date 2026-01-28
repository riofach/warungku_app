import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warungku_app/core/services/pdf_service.dart';
import 'package:warungku_app/features/pos/data/models/transaction_model.dart' as pos;
import 'package:warungku_app/features/reports/data/models/report_summary_model.dart';
import 'package:warungku_app/features/reports/data/models/top_item_model.dart';
import 'package:warungku_app/features/reports/data/providers/report_data_provider.dart';
import 'package:warungku_app/features/reports/providers/report_filter_provider.dart';

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());

final reportPdfProvider = AsyncNotifierProvider<ReportPdfNotifier, void>(() {
  return ReportPdfNotifier();
});

class ReportPdfNotifier extends AsyncNotifier<void> {
  
  @override
  FutureOr<void> build() {
    // Initial state is null (idle)
    return null;
  }

  Future<void> export() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final _pdfService = ref.read(pdfServiceProvider);
      final summaryAsync = ref.read(reportSummaryProvider);
      final transactionsAsync = ref.read(reportTransactionsProvider);
      final topItemsAsync = ref.read(topSellingItemsProvider);
      final filter = ref.read(reportFilterProvider);

      // Validation
      if (summaryAsync.isLoading || transactionsAsync.isLoading || topItemsAsync.isLoading) {
        throw Exception('Data laporan sedang dimuat. Harap tunggu.');
      }

      if (!summaryAsync.hasValue || !transactionsAsync.hasValue || !topItemsAsync.hasValue) {
        throw Exception('Data laporan tidak tersedia.');
      }

      // Determine period string
      String period = 'Custom';
      switch (filter.period) {
        case ReportPeriod.today:
          period = 'Hari Ini';
          break;
        case ReportPeriod.week:
          period = 'Minggu Ini';
          break;
        case ReportPeriod.month:
          period = 'Bulan Ini';
          break;
        case ReportPeriod.custom:
          period = '${filter.dateRange.start.day}/${filter.dateRange.start.month} - ${filter.dateRange.end.day}/${filter.dateRange.end.month}';
          break;
      }

      // Map transactions
      final transactionsList = transactionsAsync.value!.map((t) {
        return pos.Transaction(
          id: t.id,
          code: t.code,
          adminId: t.adminId,
          paymentMethod: t.paymentMethod,
          cashReceived: t.cashReceived,
          changeAmount: t.changeAmount,
          total: t.total,
          createdAt: t.createdAt,
        );
      }).toList();

      await _pdfService.generateReport(
        summary: summaryAsync.value!,
        transactions: transactionsList,
        topItems: topItemsAsync.value!,
        period: period,
      );
    });
  }
}
