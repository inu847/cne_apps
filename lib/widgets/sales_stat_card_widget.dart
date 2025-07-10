import 'package:flutter/material.dart';

class SalesStatCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double changePercentage;
  final bool isCurrency;

  const SalesStatCardWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.changePercentage,
    this.isCurrency = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final trend = changePercentage > 0 ? 'up' : (changePercentage < 0 ? 'down' : 'neutral');
    final displayPercentage = changePercentage.abs().toStringAsFixed(1);
    
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getTrendColor(trend).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  trend == 'up' ? Icons.arrow_upward : (trend == 'down' ? Icons.arrow_downward : Icons.remove),
                  color: _getTrendColor(trend),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '$displayPercentage%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getTrendColor(trend),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dibanding periode sebelumnya',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'up':
        return Colors.green.shade700;
      case 'down':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  // Helper untuk format angka dengan pemisah ribuan
  static String formatCurrency(double value) {
    return 'Rp ${value.toInt().toString().replaceAllMapped(
          RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[0]}.',
        )}';
  }

  // Helper untuk format angka biasa dengan pemisah ribuan
  static String formatNumber(double value) {
    return value.toInt().toString().replaceAllMapped(
          RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[0]}.',
        );
  }
}