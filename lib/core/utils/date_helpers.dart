class DateHelpers {
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime getStartOfNextDay(DateTime date) {
    return DateTime(date.year, date.month, date.day).add(const Duration(days: 1));
  }

  static DateTime getStartOfWeek(DateTime date) {
    // Assuming Monday is start of week (standard in Indonesia)
    // weekday 1 = Monday, 7 = Sunday
    return getStartOfDay(date.subtract(Duration(days: date.weekday - 1)));
  }

  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
}
