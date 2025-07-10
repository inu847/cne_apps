class SalesDashboardData {
  final PeriodData currentPeriod;
  final PeriodData previousPeriod;
  final ComparisonData comparison;
  final DailySalesData dailySales;

  SalesDashboardData({
    required this.currentPeriod,
    required this.previousPeriod,
    required this.comparison,
    required this.dailySales,
  });

  factory SalesDashboardData.fromJson(Map<String, dynamic> json) {
    return SalesDashboardData(
      currentPeriod: PeriodData.fromJson(json['current_period']),
      previousPeriod: PeriodData.fromJson(json['previous_period']),
      comparison: ComparisonData.fromJson(json['comparison']),
      dailySales: DailySalesData.fromJson(json['daily_sales']),
    );
  }
}

class PeriodData {
  final double totalSales;
  final int transactionCount;
  final double averageTransactionValue;
  final double totalProfit;
  final double profitMargin;

  PeriodData({
    required this.totalSales,
    required this.transactionCount,
    required this.averageTransactionValue,
    required this.totalProfit,
    required this.profitMargin,
  });

  factory PeriodData.fromJson(Map<String, dynamic> json) {
    return PeriodData(
      totalSales: json['total_sales'].toDouble(),
      transactionCount: json['transaction_count'],
      averageTransactionValue: json['average_transaction_value'].toDouble(),
      totalProfit: json['total_profit'].toDouble(),
      profitMargin: json['profit_margin'].toDouble(),
    );
  }
}

class ComparisonData {
  final double totalSalesChange;
  final double transactionCountChange;
  final double averageTransactionValueChange;
  final double profitChange;
  final double profitMarginChange;

  ComparisonData({
    required this.totalSalesChange,
    required this.transactionCountChange,
    required this.averageTransactionValueChange,
    required this.profitChange,
    required this.profitMarginChange,
  });

  factory ComparisonData.fromJson(Map<String, dynamic> json) {
    return ComparisonData(
      totalSalesChange: json['total_sales_change'].toDouble(),
      transactionCountChange: json['transaction_count_change'].toDouble(),
      averageTransactionValueChange: json['average_transaction_value_change'].toDouble(),
      profitChange: json['profit_change'].toDouble(),
      profitMarginChange: json['profit_margin_change'].toDouble(),
    );
  }
}

class DailySalesData {
  final List<String> labels;
  final List<double> data;

  DailySalesData({
    required this.labels,
    required this.data,
  });

  factory DailySalesData.fromJson(Map<String, dynamic> json) {
    return DailySalesData(
      labels: List<String>.from(json['labels']),
      data: List<double>.from(json['data'].map((x) => x.toDouble())),
    );
  }
}