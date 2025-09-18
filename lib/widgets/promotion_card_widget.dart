import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/promotion_model.dart';
import '../services/promotion_service.dart';
import '../config/api_config.dart';

class PromotionCardWidget extends StatelessWidget {
  final Promotion promotion;
  final bool isCompact;
  final VoidCallback? onTap;

  const PromotionCardWidget({
    super.key,
    required this.promotion,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap ?? () => _handlePromotionTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: isCompact ? const EdgeInsets.all(18) : const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _getGradientForType(promotion.type),
          ),
          child: isCompact ? _buildCompactLayout(context) : _buildFullLayout(context),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with type badge and discount
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                promotion.typeDisplayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Discount badge
            if (promotion.formattedDiscountText.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  promotion.formattedDiscountText,
                  style: TextStyle(
                    color: ApiConfig.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Title
        Text(
          promotion.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        
        // Description
        Expanded(
          child: Text(
            promotion.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 12),
        
        // Footer with validity and action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Validity period
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Berlaku hingga:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    promotion.formattedEndDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFullLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with type badge and discount
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                promotion.typeDisplayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (promotion.formattedDiscountText.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  promotion.formattedDiscountText,
                  style: TextStyle(
                    color: ApiConfig.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Title
        Text(
          promotion.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        
        // Description
        Text(
          promotion.description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        
        // Promo code if available
        if (promotion.promoCode != null && promotion.promoCode!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_offer,
                  color: Colors.white.withOpacity(0.9),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kode: ${promotion.promoCode}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Footer with validity and action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Validity period
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Berlaku hingga:',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                Text(
                  promotion.formattedEndDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            // Action button
            if (promotion.linkText != null && promotion.linkText!.isNotEmpty)
              ElevatedButton(
                onPressed: () => _showPromotionDetails(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ApiConfig.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  promotion.linkText!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  LinearGradient _getGradientForType(String type) {
    switch (type) {
      case 'discount':
        return LinearGradient(
          colors: [
            ApiConfig.primaryColor,
            ApiConfig.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'cashback':
        return const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF45A049),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'special_offer':
        return const LinearGradient(
          colors: [
            Color(0xFFFF9800),
            Color(0xFFFF8F00),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [
            ApiConfig.primaryColor,
            ApiConfig.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  void _handlePromotionTap(BuildContext context) async {
    // Record view for analytics
    final promotionService = PromotionService();
    promotionService.recordPromotionView(promotion.id);
    
    // Show promotion details dialog
    _showPromotionDetails(context);
  }

  void _showPromotionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PromotionDetailDialog(promotion: promotion),
    );
  }
}

class PromotionDetailDialog extends StatelessWidget {
  final Promotion promotion;

  const PromotionDetailDialog({
    super.key,
    required this.promotion,
  });

  Future<void> _launchURL(String url, BuildContext context) async {
    try {
      // Validate URL format
      if (url.isEmpty) {
        throw Exception('URL is empty');
      }
      
      // Ensure URL has proper scheme
      String validUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        validUrl = 'https://$url';
      }
      
      print('Attempting to launch URL: $validUrl');
      
      final Uri uri = Uri.parse(validUrl);
      print('Parsed URI: $uri');
      
      // Check if URL can be launched
      final bool canLaunch = await canLaunchUrl(uri);
      print('Can launch URL: $canLaunch');
      
      if (canLaunch) {
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('URL launched successfully: $launched');
        
        if (!launched) {
          throw Exception('Failed to launch URL despite canLaunchUrl returning true');
        }
      } else {
        print('Cannot launch URL: $validUrl');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak dapat membuka link: $validUrl\nPastikan ada aplikasi browser yang terinstal.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Error launching URL: $e');
      print('Stack trace: $stackTrace');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat membuka link: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _getGradientForType(promotion.type),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promotion.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          promotion.typeDisplayName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      promotion.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Content
                    Text(
                      promotion.content,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    
                    // Promo code
                    if (promotion.promoCode != null && promotion.promoCode!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ApiConfig.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ApiConfig.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Kode Promo',
                              style: TextStyle(
                                color: ApiConfig.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              promotion.promoCode!,
                              style: TextStyle(
                                color: ApiConfig.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Terms and conditions
                    if (promotion.termsConditions.isNotEmpty) ...[
                      Text(
                        'Syarat & Ketentuan:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ApiConfig.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...promotion.termsConditions.map((term) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(color: ApiConfig.primaryColor)),
                            Expanded(child: Text(term, style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                      const SizedBox(height: 20),
                    ],
                    
                    // Validity
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Periode Berlaku',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            promotion.formattedDateRange,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Action button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Close button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ApiConfig.primaryColor,
                        side: BorderSide(color: ApiConfig.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  // URL action button (if available)
                  if (promotion.linkUrl != null && promotion.linkUrl!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final promotionService = PromotionService();
                          promotionService.recordPromotionClick(promotion.id);
                          await _launchURL(promotion.linkUrl!, context);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ApiConfig.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          promotion.linkText ?? 'Buka Link',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getGradientForType(String type) {
    switch (type) {
      case 'discount':
        return LinearGradient(
          colors: [
            ApiConfig.primaryColor,
            ApiConfig.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'cashback':
        return const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF45A049),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'special_offer':
        return const LinearGradient(
          colors: [
            Color(0xFFFF9800),
            Color(0xFFFF8F00),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [
            ApiConfig.primaryColor,
            ApiConfig.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}