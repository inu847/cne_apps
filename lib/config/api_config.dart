import 'package:flutter/material.dart';

class ApiConfig {
  // Base URL for API
  // static const String baseUrl = 'http://cne.test/api';
  static const String baseUrl = 'https://dompetkasir.com/api';
  
  // Theme Colors Configuration
  static const Color primaryColor = Color(0xFF03D26F); // Hijau primer
  static const Color secondaryColor = Color(0xFF17A899); // #17a899 (hijau tosca)
  static const Color accentColor = Color(0xFF6FEF78); // #6fef78 (hijau terang)
  static const Color backgroundColor = Color(0xFFEAF4F4); // Background terang
  static const Color textColor = Color(0xFF161514); // Teks gelap
  
  // API Endpoints
  // Karena baseUrl sudah termasuk '/api', kita tidak perlu menambahkan '/api' lagi
  static const String loginEndpoint = '$baseUrl/login';
  static const String logoutEndpoint = '$baseUrl/logout';
  static const String categoriesEndpoint = '$baseUrl/categories';
  static const String productsEndpoint = '$baseUrl/products';
  static const String settingsEndpoint = '$baseUrl/settings';
  static const String ordersEndpoint = '$baseUrl/orders';
  static const String transactionsEndpoint = '$baseUrl/transactions';
  static const String dailyRecapEndpoint = '$baseUrl/transactions/daily-recap';
  static const String dailyRecapDetailsEndpoint = '$baseUrl/transactions/daily-recap/details';
  static const String paymentMethodsEndpoint = '$baseUrl/payment-methods';
  static const String dailyInventoryStocksEndpoint = '$baseUrl/daily-inventory-stocks';
  static const String warehousesEndpoint = '$baseUrl/warehouses';
  static const String inventoryItemsEndpoint = '$baseUrl/inventory-items';
  static const String pettyCashEndpoint = '$baseUrl/petty-cash';
  static const String pettyCashOpeningEndpoint = '$baseUrl/petty-cash/opening';
  static const String pettyCashActiveOpeningEndpoint = '$baseUrl/petty-cash/active-opening';
  static const String pettyCashClosingEndpoint = '$baseUrl/petty-cash/closing';
  static const String promotionsEndpoint = '$baseUrl/promotions';
  static const String activePromotionsEndpoint = '$baseUrl/promotions/active';
  
  // Token Key for SharedPreferences
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  
  // Debug helper
  static void printEndpoints() {
    print('ApiConfig: Base URL - $baseUrl');
    print('ApiConfig: Login Endpoint - $loginEndpoint');
    print('ApiConfig: Logout Endpoint - $logoutEndpoint');
    print('ApiConfig: Categories Endpoint - $categoriesEndpoint');
    print('ApiConfig: Products Endpoint - $productsEndpoint');
    print('ApiConfig: Settings Endpoint - $settingsEndpoint');
    print('ApiConfig: Orders Endpoint - $ordersEndpoint');
    print('ApiConfig: Transactions Endpoint - $transactionsEndpoint');
    print('ApiConfig: Payment Methods Endpoint - $paymentMethodsEndpoint');
    print('ApiConfig: Daily Inventory Stocks Endpoint - $dailyInventoryStocksEndpoint');
    print('ApiConfig: Warehouses Endpoint - $warehousesEndpoint');
    print('ApiConfig: Inventory Items Endpoint - $inventoryItemsEndpoint');
    print('ApiConfig: Petty Cash Endpoint - $pettyCashEndpoint');
    print('ApiConfig: Petty Cash Opening Endpoint - $pettyCashOpeningEndpoint');
    print('ApiConfig: Petty Cash Active Opening Endpoint - $pettyCashActiveOpeningEndpoint');
    print('ApiConfig: Petty Cash Closing Endpoint - $pettyCashClosingEndpoint');
  }
}