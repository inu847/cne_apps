import 'package:flutter/material.dart';
import '../models/promotion_model.dart';
import '../services/promotion_service.dart';
import '../config/api_config.dart';
import 'promotion_card_widget.dart';

class PromotionSectionWidget extends StatefulWidget {
  final bool isTablet;

  const PromotionSectionWidget({
    super.key,
    this.isTablet = false,
  });

  @override
  State<PromotionSectionWidget> createState() => _PromotionSectionWidgetState();
}

class _PromotionSectionWidgetState extends State<PromotionSectionWidget> {
  final PromotionService _promotionService = PromotionService();
  List<Promotion> _promotions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      print('PromotionSectionWidget: Starting to load promotions...');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final promotions = await _promotionService.getActivePromotions();
      print('PromotionSectionWidget: Loaded ${promotions.length} promotions');
      
      setState(() {
        _promotions = promotions;
        _isLoading = false;
      });
    } catch (e) {
      print('PromotionSectionWidget: Error loading promotions: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_promotions.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPromotionSection();
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 16),
          SizedBox(
            height: widget.isTablet ? 240 : 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                width: widget.isTablet ? 350 : 280,
                margin: EdgeInsets.only(
                  left: index == 0 ? 16 : 8,
                  right: index == 2 ? 16 : 8,
                ),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 20,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade400,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat promosi',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Terjadi kesalahan saat memuat data promosi. Silakan coba lagi.',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadPromotions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ApiConfig.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  color: Colors.grey.shade400,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum ada promosi',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Saat ini belum ada promosi yang tersedia. Periksa kembali nanti.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 16),
          SizedBox(
            height: widget.isTablet ? 200 : 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _promotions.length,
              itemBuilder: (context, index) {
                final promotion = _promotions[index];
                return Container(
                  width: widget.isTablet ? 350 : 280,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 16 : 8,
                    right: index == _promotions.length - 1 ? 16 : 8,
                  ),
                  child: PromotionCardWidget(
                    promotion: promotion,
                    isCompact: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer,
                color: ApiConfig.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Promosi & Penawaran',
                style: TextStyle(
                  fontSize: widget.isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: ApiConfig.textColor,
                ),
              ),
            ],
          ),
          if (_promotions.isNotEmpty)
            TextButton(
              onPressed: () => _showAllPromotions(),
              child: Text(
                'Lihat Semua',
                style: TextStyle(
                  color: ApiConfig.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAllPromotions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      color: ApiConfig.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Semua Promosi & Penawaran',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Promotions list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _promotions.length,
                  itemBuilder: (context, index) {
                    final promotion = _promotions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: PromotionCardWidget(
                        promotion: promotion,
                        isCompact: false,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}