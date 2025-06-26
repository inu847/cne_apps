import 'package:flutter/material.dart';

import '../utils/format_utils.dart';

class Product {
  final int id;
  final String name;
  final String? sku;
  final String? barcode;
  final String? description;
  final int price;
  final int? cost;
  final int stock;
  final int categoryId;
  final String categoryName;
  final bool isActive;
  final bool hasVariations;
  final List<ProductVariation>? variations;
  final IconData icon; // Untuk tampilan UI

  Product({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.description,
    required this.price,
    this.cost,
    required this.stock,
    required this.categoryId,
    required this.categoryName,
    required this.isActive,
    required this.hasVariations,
    this.variations,
    required this.icon,
  });

  // Utility methods moved to FormatUtils class in utils/format_utils.dart

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
    // Menentukan icon berdasarkan kategori
    IconData getIconForCategory(String category) {
      switch (category.toLowerCase()) {
        case 'elektronik':
          return Icons.devices;
        case 'pakaian':
          return Icons.checkroom;
        case 'makanan':
          return Icons.restaurant;
        case 'minuman':
          return Icons.local_drink;
        case 'kesehatan':
          return Icons.health_and_safety;
        case 'kecantikan':
          return Icons.face;
        case 'rumah tangga':
          return Icons.home;
        case 'olahraga':
          return Icons.sports_soccer;
        case 'mainan':
          return Icons.toys;
        case 'buku':
          return Icons.book;
        default:
          return Icons.inventory_2;
      }
    }

    List<ProductVariation>? variations;
    if (json['variations'] != null) {
      variations = List<ProductVariation>.from(
        json['variations'].map((v) => ProductVariation.fromJson(v)),
      );
    }

    return Product(
      id: FormatUtils.safeParseInt(json['id']),
      name: json['name'],
      sku: json['sku'],
      barcode: json['barcode'],
      description: json['description'],
      price: FormatUtils.safeParseInt(json['price']),
      cost: json['cost'] == null ? null : FormatUtils.safeParseInt(json['cost']),
      stock: FormatUtils.safeParseInt(json['stock']),
      categoryId: FormatUtils.safeParseInt(json['category_id']),
      categoryName: json['category_name'],
      isActive: json['is_active'],
      hasVariations: json['has_variations'],
      variations: variations,
      icon: getIconForCategory(json['category_name']),
    );
    } catch (e) {
      print('Error parsing Product JSON: $e');
      print('Problematic JSON: $json');
      // Return a default product with minimal data to prevent app crashes
      return Product(
        id: json['id'] is int ? json['id'] : 0,
        name: json['name'] ?? 'Unknown Product',
        price: 0,
        stock: 0,
        categoryId: 0,
        categoryName: json['category_name'] ?? 'Uncategorized',
        isActive: false,
        hasVariations: false,
        icon: Icons.error_outline,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'description': description,
      'price': price,
      'cost': cost,
      'stock': stock,
      'category_id': categoryId,
      'category_name': categoryName,
      'is_active': isActive,
      'has_variations': hasVariations,
      'variations': variations?.map((v) => v.toJson()).toList(),
    };
  }

  // Konversi ke format yang digunakan di keranjang
  Map<String, dynamic> toCartFormat() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': categoryName,
      'icon': icon,
    };
  }
}

class ProductVariation {
  final int id;
  final String name;
  final List<VariationOption> options;

  ProductVariation({
    required this.id,
    required this.name,
    required this.options,
  });

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    try {
      return ProductVariation(
        id: FormatUtils.safeParseInt(json['id']),
        name: json['name'] ?? '',
        options: json['options'] != null
            ? List<VariationOption>.from(
                json['options'].map((x) => VariationOption.fromJson(x)))
            : [],
      );
    } catch (e) {
      print('Error parsing ProductVariation JSON: $e');
      print('Problematic JSON: $json');
      return ProductVariation(
        id: 0,
        name: json['name'] ?? 'Unknown Variation',
        options: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}

class VariationOption {
  final int id;
  final String name;
  final int priceAdjustment;
  final int stock;

  VariationOption({
    required this.id,
    required this.name,
    required this.priceAdjustment,
    required this.stock,
  });

  factory VariationOption.fromJson(Map<String, dynamic> json) {
    try {
      return VariationOption(
        id: FormatUtils.safeParseInt(json['id']),
        name: json['name'] ?? '',
        priceAdjustment: FormatUtils.safeParseInt(json['price_adjustment']),
        stock: FormatUtils.safeParseInt(json['stock']),
      );
    } catch (e) {
      print('Error parsing VariationOption JSON: $e');
      print('Problematic JSON: $json');
      return VariationOption(
        id: 0,
        name: json['name'] ?? 'Unknown Option',
        priceAdjustment: 0,
        stock: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price_adjustment': priceAdjustment,
      'stock': stock,
    };
  }
}