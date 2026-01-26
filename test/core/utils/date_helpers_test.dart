import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/core/utils/date_helpers.dart';

void main() {
  group('DateHelpers', () {
    test('getStartOfDay returns correct time (00:00:00)', () {
      final date = DateTime(2026, 1, 25, 14, 30, 45);
      final start = DateHelpers.getStartOfDay(date);
      expect(start.year, 2026);
      expect(start.month, 1);
      expect(start.day, 25);
      expect(start.hour, 0);
      expect(start.minute, 0);
      expect(start.second, 0);
      expect(start.millisecond, 0);
    });

    test('getStartOfNextDay returns correct time (Next Day 00:00:00)', () {
      final date = DateTime(2026, 1, 25, 14, 30, 45);
      final nextDay = DateHelpers.getStartOfNextDay(date);
      expect(nextDay.year, 2026);
      expect(nextDay.month, 1);
      expect(nextDay.day, 26);
      expect(nextDay.hour, 0);
      expect(nextDay.minute, 0);
      expect(nextDay.second, 0);
      expect(nextDay.millisecond, 0);
    });

    test('getStartOfWeek returns previous Monday', () {
      // Jan 25 2026 is Sunday. Monday was Jan 19.
      // Wait, let's verify.
      // 2026-01-01 is Thursday?
      // I'll trust the logic: date.subtract(Duration(days: date.weekday - 1))
      // If today is Monday (1), subtract 0 days. Correct.
      // If today is Sunday (7), subtract 6 days.
      
      final date = DateTime(2026, 1, 25); // Sunday
      expect(date.weekday, 7); 
      
      final startOfWeek = DateHelpers.getStartOfWeek(date);
      // Should be Jan 19
      expect(startOfWeek.day, 19);
      expect(startOfWeek.month, 1);
      expect(startOfWeek.year, 2026);
      expect(startOfWeek.hour, 0);
    });

    test('getStartOfMonth returns 1st day of month', () {
      final date = DateTime(2026, 1, 25);
      final startOfMonth = DateHelpers.getStartOfMonth(date);
      expect(startOfMonth.day, 1);
      expect(startOfMonth.month, 1);
      expect(startOfMonth.year, 2026);
      expect(startOfMonth.hour, 0);
    });
  });
}
