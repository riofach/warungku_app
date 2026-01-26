import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warungku_app/features/reports/providers/report_filter_provider.dart';

void main() {
  group('ReportFilterNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is ReportPeriod.today', () {
      final state = container.read(reportFilterProvider);
      final now = DateTime.now();

      expect(state.period, ReportPeriod.today);
      // Compare dates ignoring time
      expect(state.dateRange.start.year, now.year);
      expect(state.dateRange.start.month, now.month);
      expect(state.dateRange.start.day, now.day);
      expect(state.dateRange.end.year, now.year);
      expect(state.dateRange.end.month, now.month);
      expect(state.dateRange.end.day, now.day);
    });

    test('setPeriod to week updates date range correctly', () {
      final notifier = container.read(reportFilterProvider.notifier);
      notifier.setPeriod(ReportPeriod.week);

      final state = container.read(reportFilterProvider);
      expect(state.period, ReportPeriod.week);

      final now = DateTime.now();
      // Calculate expected start of week (Monday)
      // weekday: Mon=1, Sun=7
      final daysToSubtract = now.weekday - 1;
      final startOfWeek = now.subtract(Duration(days: daysToSubtract));
      // Calculate expected end of week (Sunday)
      final daysToAdd = 7 - now.weekday;
      final endOfWeek = now.add(Duration(days: daysToAdd));

      expect(state.dateRange.start.year, startOfWeek.year);
      expect(state.dateRange.start.month, startOfWeek.month);
      expect(state.dateRange.start.day, startOfWeek.day);
      
      expect(state.dateRange.end.year, endOfWeek.year);
      expect(state.dateRange.end.month, endOfWeek.month);
      expect(state.dateRange.end.day, endOfWeek.day);
    });

    test('setPeriod to month updates date range correctly', () {
      final notifier = container.read(reportFilterProvider.notifier);
      notifier.setPeriod(ReportPeriod.month);

      final state = container.read(reportFilterProvider);
      expect(state.period, ReportPeriod.month);

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0); // Day 0 of next month = last day of current

      expect(state.dateRange.start.year, startOfMonth.year);
      expect(state.dateRange.start.month, startOfMonth.month);
      expect(state.dateRange.start.day, startOfMonth.day);
      
      expect(state.dateRange.end.year, lastDay.year);
      expect(state.dateRange.end.month, lastDay.month);
      expect(state.dateRange.end.day, lastDay.day);
    });

    test('setCustomRange updates period to custom and sets range', () {
      final notifier = container.read(reportFilterProvider.notifier);
      final customStart = DateTime(2025, 1, 1);
      final customEnd = DateTime(2025, 1, 31);
      final customRange = DateTimeRange(start: customStart, end: customEnd);

      notifier.setCustomRange(customRange);

      final state = container.read(reportFilterProvider);
      expect(state.period, ReportPeriod.custom);
      expect(state.dateRange, customRange);
    });
  });
}
