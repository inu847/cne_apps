class ApiConfig {
  // Base URL for API
  static const String baseUrl = 'http://cne.test/api';
  // static const String baseUrl = 'https://cjxa6v1p84.sharedwithexpose.com/api';
  
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
  }
}