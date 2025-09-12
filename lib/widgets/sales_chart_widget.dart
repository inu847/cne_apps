import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sales_dashboard_model.dart';
import '../utils/currency_formatter.dart';

class SalesChartWidget extends StatelessWidget {
  final DailySalesData dailySalesData;
  final bool isMobile;

  const SalesChartWidget({
    Key? key,
    required this.dailySalesData,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Cek apakah data kosong
    if (dailySalesData.data.isEmpty || dailySalesData.labels.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Penjualan Harian',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2A78).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: const Color(0xFF1E2A78),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${dailySalesData.labels.first} - ${dailySalesData.labels.last}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E2A78),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: isMobile ? 200 : 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: _calculateYAxisInterval(),
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: _calculateBottomTitleInterval(),
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < dailySalesData.labels.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            dailySalesData.labels[value.toInt()],
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _calculateYAxisInterval(),
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          _formatYAxisValue(value),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  left: BorderSide(color: Colors.grey.shade300, width: 1),
                  right: BorderSide(color: Colors.transparent),
                  top: BorderSide(color: Colors.transparent),
                ),
              ),
              minX: 0,
              maxX: (dailySalesData.labels.length - 1).toDouble(),
              minY: 0,
              maxY: _calculateMaxY(),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: const Color(0xFF1E2A78),
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final index = barSpot.x.toInt();
                      if (index >= 0 && index < dailySalesData.labels.length) {
                        return LineTooltipItem(
                          '${dailySalesData.labels[index]}\n',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: CurrencyFormatter.formatCurrency(barSpot.y),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
                            ),
                          ],
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(dailySalesData.data.length, (index) {
                    return FlSpot(index.toDouble(), dailySalesData.data[index]);
                  }),
                  isCurved: true,
                  color: const Color(0xFF1E2A78),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF1E2A78).withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: isMobile ? 48 : 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data penjualan harian',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data penjualan harian akan ditampilkan di sini',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateMaxY() {
    if (dailySalesData.data.isEmpty) return 1000;
    final maxValue = dailySalesData.data.reduce((a, b) => a > b ? a : b);
    // Tambahkan 20% untuk ruang di atas grafik
    return maxValue * 1.2;
  }

  double _calculateYAxisInterval() {
    final maxY = _calculateMaxY();
    if (maxY <= 1000) return 200;
    if (maxY <= 10000) return 2000;
    if (maxY <= 100000) return 20000;
    if (maxY <= 1000000) return 200000;
    return 1000000;
  }

  double _calculateBottomTitleInterval() {
    final length = dailySalesData.labels.length;
    if (isMobile) {
      if (length <= 5) return 1;
      if (length <= 10) return 2;
      return (length / 5).ceil().toDouble();
    } else {
      if (length <= 10) return 1;
      if (length <= 20) return 2;
      return (length / 10).ceil().toDouble();
    }
  }

  String _formatYAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toInt().toString();
  }
}