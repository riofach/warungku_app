class ReportSummary {
  final int totalRevenue;
  final int totalProfit;
  final int transactionCount;
  final int averageValue;
  final int posCount;
  final int posRevenue;
  final int orderCount;
  final int orderRevenue;

  const ReportSummary({
    required this.totalRevenue,
    required this.totalProfit,
    required this.transactionCount,
    required this.averageValue,
    this.posCount = 0,
    this.posRevenue = 0,
    this.orderCount = 0,
    this.orderRevenue = 0,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalRevenue: json['total_revenue'] as int? ?? 0,
      totalProfit: json['total_profit'] as int? ?? 0,
      transactionCount: json['transaction_count'] as int? ?? 0,
      averageValue: json['average_value'] as int? ?? 0,
      posCount: json['pos_count'] as int? ?? 0,
      posRevenue: json['pos_revenue'] as int? ?? 0,
      orderCount: json['order_count'] as int? ?? 0,
      orderRevenue: json['order_revenue'] as int? ?? 0,
    );
  }

  factory ReportSummary.empty() {
    return const ReportSummary(
      totalRevenue: 0,
      totalProfit: 0,
      transactionCount: 0,
      averageValue: 0,
    );
  }
}
