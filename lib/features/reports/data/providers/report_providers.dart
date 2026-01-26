import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: deprecated_member_use
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../models/top_item_model.dart';
import '../repositories/report_repository.dart';
import '../../../../core/constants/app_constants.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final supabase = Supabase.instance.client;
  return ReportRepository(supabase);
});

enum ReportPeriod { today, thisWeek, thisMonth }

extension ReportPeriodExtension on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.today:
        return AppConstants.dashboardPeriodToday;
      case ReportPeriod.thisWeek:
        return AppConstants.dashboardPeriodWeek;
      case ReportPeriod.thisMonth:
        return AppConstants.dashboardPeriodMonth;
    }
  }
}

final reportPeriodProvider = StateProvider.autoDispose<ReportPeriod>(
  (ref) => ReportPeriod.today,
);

final topSellingItemsProvider = FutureProvider.autoDispose<List<TopItem>>((
  ref,
) async {
  final repository = ref.watch(reportRepositoryProvider);
  final period = ref.watch(reportPeriodProvider);
  final now = DateTime.now();

  DateTime start = DateHelpers.getStartOfDay(now);
  DateTime end = DateHelpers.getStartOfNextDay(now);

  switch (period) {
    case ReportPeriod.today:
      start = DateHelpers.getStartOfDay(now);
      break;
    case ReportPeriod.thisWeek:
      start = DateHelpers.getStartOfWeek(now);
      break;
    case ReportPeriod.thisMonth:
      start = DateHelpers.getStartOfMonth(now);
      break;
  }

  return repository.getTopSellingItems(start, end);
});
