import 'package:flutter/material.dart';
import 'dart:async';
import '../services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();
  
  bool _isOnline = true;
  bool _isManualOfflineMode = false;
  StreamSubscription<bool>? _connectionSubscription;
  
  // Getters
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get isManualOfflineMode => _isManualOfflineMode;
  
  String get statusMessage => _connectivityService.getStatusMessage();
  String get statusColor => _connectivityService.getStatusColor();

  ConnectivityProvider() {
    _initializeConnectivity();
  }

  // Inisialisasi connectivity service
  Future<void> _initializeConnectivity() async {
    await _connectivityService.initialize();
    
    // Set initial state
    _isOnline = _connectivityService.isOnlineMode;
    _isManualOfflineMode = _connectivityService.isManualOfflineMode;
    
    // Listen untuk perubahan koneksi
    _connectionSubscription = _connectivityService.connectionStream.listen(
      (bool isConnected) {
        _isOnline = isConnected;
        _isManualOfflineMode = _connectivityService.isManualOfflineMode;
        notifyListeners();
      },
    );
    
    notifyListeners();
  }

  // Switch ke offline mode secara manual
  void switchToOfflineMode() {
    _connectivityService.switchToOfflineMode();
    _isOnline = false;
    _isManualOfflineMode = true;
    notifyListeners();
  }

  // Switch ke online mode secara manual
  void switchToOnlineMode() {
    _connectivityService.switchToOnlineMode();
    _isOnline = _connectivityService.isConnected;
    _isManualOfflineMode = false;
    notifyListeners();
  }

  // Toggle mode
  void toggleMode() {
    if (_isManualOfflineMode) {
      switchToOnlineMode();
    } else {
      switchToOfflineMode();
    }
  }

  // Cek apakah fitur tersedia dalam mode saat ini
  bool isFeatureAvailable(String feature) {
    return _connectivityService.isFeatureAvailable(feature);
  }

  // Cek apakah dapat mengakses fitur tertentu
  bool canAccessFeature(String feature) {
    if (isOnline) {
      return true; // Semua fitur tersedia dalam online mode
    }
    
    // Dalam offline mode, hanya fitur tertentu yang tersedia
    final allowedOfflineFeatures = [
      'pos',
      'transactions',
      'home',
      'dashboard', // Dashboard mungkin perlu akses terbatas
    ];
    
    return allowedOfflineFeatures.contains(feature.toLowerCase());
  }

  // Get pesan error untuk fitur yang tidak tersedia
  String getFeatureUnavailableMessage(String feature) {
    if (isOffline) {
      return 'Fitur $feature tidak tersedia dalam mode offline. Silakan beralih ke mode online untuk mengakses fitur ini.';
    }
    return 'Fitur $feature tidak tersedia saat ini.';
  }

  // Show dialog untuk fitur yang tidak tersedia
  void showFeatureUnavailableDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Fitur Tidak Tersedia'),
          content: Text(getFeatureUnavailableMessage(feature)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (isOffline && !_isManualOfflineMode)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Tidak bisa switch otomatis jika tidak ada koneksi
                },
                child: const Text('Coba Lagi'),
              ),
            if (_isManualOfflineMode)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  switchToOnlineMode();
                },
                child: const Text('Beralih ke Online'),
              ),
          ],
        );
      },
    );
  }

  // Get icon untuk status
  IconData getStatusIcon() {
    if (isOnline) {
      return Icons.wifi;
    } else if (_isManualOfflineMode) {
      return Icons.wifi_off;
    } else {
      return Icons.signal_wifi_connected_no_internet_4;
    }
  }

  // Get color untuk status
  Color getStatusIconColor() {
    if (isOnline) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _connectivityService.dispose();
    super.dispose();
  }
}