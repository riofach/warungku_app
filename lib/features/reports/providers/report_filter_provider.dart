import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReportPeriod { today, week, month, custom }

class ReportFilterState {
  final ReportPeriod period;
  final DateTimeRange dateRange;

  ReportFilterState({
    required this.period,
    required this.dateRange,
  });

  ReportFilterState copyWith({
    ReportPeriod? period,
    DateTimeRange? dateRange,
  }) {
    return ReportFilterState(
      period: period ?? this.period,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}

class ReportFilterNotifier extends Notifier<ReportFilterState> {
  @override
  ReportFilterState build() {
    final now = DateTime.now();
    // Start with Today (Full Day 00:00 - 23:59)
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return ReportFilterState(
      period: ReportPeriod.today,
      dateRange: DateTimeRange(start: start, end: end),
    );
  }

  void setPeriod(ReportPeriod period) {
    final now = DateTime.now();
    DateTimeRange newRange;

    switch (period) {
      case ReportPeriod.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        newRange = DateTimeRange(start: start, end: end);
        break;
      case ReportPeriod.week:
        // Week starts Monday (1) and ends Sunday (7)
        final daysToSubtract = now.weekday - 1;
        final startOfWeek = now.subtract(Duration(days: daysToSubtract));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        
        final daysToAdd = 7 - now.weekday;
        final endOfWeek = now.add(Duration(days: daysToAdd));
        final end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
        
        newRange = DateTimeRange(start: start, end: end);
        break;
      case ReportPeriod.month:
        final start = DateTime(now.year, now.month, 1);
        // Day 0 of next month is the last day of current month
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        final end = DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day, 23, 59, 59);
        
        newRange = DateTimeRange(start: start, end: end);
        break;
      case ReportPeriod.custom:
        newRange = state.dateRange;
        break;
    }

    state = state.copyWith(period: period, dateRange: newRange);
  }

  void setCustomRange(DateTimeRange range) {
    // Ensure custom range covers full days
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final endRaw = range.end;
    final end = DateTime(endRaw.year, endRaw.month, endRaw.day, 23, 59, 59);
    
    state = state.copyWith(
      period: ReportPeriod.custom,
      dateRange: DateTimeRange(start: start, end: end),
    );
  }
}

final reportFilterProvider = NotifierProvider<ReportFilterNotifier, ReportFilterState>(() {
  return ReportFilterNotifier();
});
