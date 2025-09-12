import 'package:flutter/material.dart';

class SalesStatCardWidget extends StatefulWidget {
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
  State<SalesStatCardWidget> createState() => _SalesStatCardWidgetState();
}

class _SalesStatCardWidgetState extends State<SalesStatCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  // Color palette
  static const Color primaryGreen = Color(0xFF03D26F);
  static const Color lightBlue = Color(0xFFEAF4F4);
  static const Color darkBlack = Color(0xFF161514);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trend = widget.changePercentage > 0 ? 'up' : (widget.changePercentage < 0 ? 'down' : 'neutral');
    final displayPercentage = widget.changePercentage.abs().toStringAsFixed(1);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    lightBlue,
                    lightBlue.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: primaryGreen.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: darkBlack.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(isMobile ? 8 : 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryGreen,
                              primaryGreen.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryGreen.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: isMobile ? 20 : 22,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                   SizedBox(height: isMobile ? 10 : 12),
                   Container(
                     padding: EdgeInsets.symmetric(
                       horizontal: isMobile ? 8 : 10, 
                       vertical: isMobile ? 4 : 6,
                     ),
                     decoration: BoxDecoration(
                       color: _getTrendColor(trend).withOpacity(0.15),
                       borderRadius: BorderRadius.circular(20),
                       border: Border.all(
                         color: _getTrendColor(trend).withOpacity(0.3),
                         width: 1,
                       ),
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Icon(
                           trend == 'up' ? Icons.trending_up : (trend == 'down' ? Icons.trending_down : Icons.remove),
                           color: _getTrendColor(trend),
                           size: isMobile ? 12 : 14,
                         ),
                         const SizedBox(width: 4),
                         Text(
                           '$displayPercentage%',
                           style: TextStyle(
                             fontSize: isMobile ? 12 : 14,
                             fontWeight: FontWeight.bold,
                             color: _getTrendColor(trend),
                           ),
                         ),
                       ],
                     ),
                   ),
                   SizedBox(height: isMobile ? 2 : 4),
                   Text(
                     'Dibanding periode sebelumnya',
                     style: TextStyle(
                       fontSize: isMobile ? 10 : 12,
                       color: darkBlack.withOpacity(0.6),
                     ),
                   ),
                 ],
               ),
             ),
           ),
         );
       },
     );
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'up':
        return Colors.green.shade700;
      case 'down':
        return Colors.red.shade700;
      default:
        return darkBlack.withOpacity(0.6);
    }
  }

}