class DashboardSummary {
  final int omset; // Total revenue today
  final int profit; // Total profit today
  final int transactionCount; // Number of transactions today
  final DateTime date;

  const DashboardSummary({
    required this.omset,
    required this.profit,
    required this.transactionCount,
    required this.date,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      omset: (json['omset'] as num?)?.toInt() ?? 0,
      profit: (json['profit'] as num?)?.toInt() ?? 0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
    );
  }

  factory DashboardSummary.empty() {
    return DashboardSummary(
      omset: 0,
      profit: 0,
      transactionCount: 0,
      date: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'omset': omset,
      'profit': profit,
      'transaction_count': transactionCount,
      'date': date.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardSummary &&
          runtimeType == other.runtimeType &&
          omset == other.omset &&
          profit == other.profit &&
          transactionCount == other.transactionCount &&
          date == other.date;

  @override
  int get hashCode =>
      omset.hashCode ^
      profit.hashCode ^
      transactionCount.hashCode ^
      date.hashCode;

  @override
  String toString() {
    return 'DashboardSummary(omset: $omset, profit: $profit, transactionCount: $transactionCount, date: $date)';
  }
}
