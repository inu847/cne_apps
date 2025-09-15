import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pos_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/reports/daily_recap_screen.dart';
import 'screens/reports/sales_report_screen.dart';
import 'services/auth_service.dart';
import 'services/receipt_service.dart';
import 'services/platform_service.dart';
import 'models/user_model.dart';
import 'providers/settings_provider.dart';
import 'providers/order_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/payment_method_provider.dart';
import 'providers/voucher_provider.dart';
import 'providers/daily_inventory_stock_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize platform service
  await initPlatformService();
  runApp(const MyApp());
}

// Initialize platform service
Future<void> initPlatformService() async {
  try {
    // Initialize the platform service
    final platformService = PlatformService();
    
    // Get platform name for logging
    final platformName = await platformService.getPlatformName();
    print('Running on platform: $platformName');
    
    // Initialize temporary directory
    final tempDir = await platformService.getTemporaryDir();
    print('Temporary directory initialized: ${tempDir.path}');
  } catch (e) {
    print('Error initializing platform service: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Removed auth checking logic as it's now handled in SplashScreen

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => PaymentMethodProvider()),
        ChangeNotifierProvider(create: (_) => VoucherProvider()),
        ChangeNotifierProvider(create: (_) => DailyInventoryStockProvider()),
      ],
      child: MaterialApp(
      navigatorKey: navigatorKey,
      title: 'DompetKasir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade800),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/pos': (context) => const POSScreen(),
        '/transactions': (context) => const TransactionsScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/reports/daily-recap': (context) => const DailyRecapScreen(),
        '/reports/sales': (context) => const SalesReportScreen(),
      },
    ));
  }
}
