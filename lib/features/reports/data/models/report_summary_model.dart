class ReportSummary {
  final int totalRevenue;
  final int totalProfit;
  final int transactionCount;
  final int averageValue;

  const ReportSummary({
    required this.totalRevenue,
    required this.totalProfit,
    required this.transactionCount,
    required this.averageValue,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalRevenue: json['total_revenue'] as int? ?? 0,
      totalProfit: json['total_profit'] as int? ?? 0,
      transactionCount: json['transaction_count'] as int? ?? 0,
      averageValue: json['average_value'] as int? ?? 0,
    );
  }

  /// Initial empty state
  factory ReportSummary.empty() {
    return const ReportSummary(
      totalRevenue: 0,
      totalProfit: 0,
      transactionCount: 0,
      averageValue: 0,
    );
  }
}
