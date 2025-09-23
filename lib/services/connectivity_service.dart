import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  bool _isConnected = true;
  bool _isManualOfflineMode = false;
  
  // Getters
  bool get isConnected => _isConnected && !_isManualOfflineMode;
  bool get isOnlineMode => isConnected;
  bool get isOfflineMode => !isConnected;
  bool get isManualOfflineMode => _isManualOfflineMode;
  
  // Stream untuk mendengarkan perubahan status koneksi
  Stream<bool> get connectionStream => _connectionStatusController.stream;

  // Inisialisasi service
  Future<void> initialize() async {
    // Cek koneksi awal
    await _checkInitialConnection();
    
    // Listen untuk perubahan koneksi
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  // Cek koneksi awal saat aplikasi dimulai
  Future<void> _checkInitialConnection() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasConnection = await _hasInternetConnection(connectivityResults);
      _updateConnectionStatus(hasConnection);
    } catch (e) {
      _updateConnectionStatus(false);
    }
  }

  // Handler untuk perubahan koneksi
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final hasConnection = await _hasInternetConnection(results);
    _updateConnectionStatus(hasConnection);
  }

  // Cek apakah benar-benar ada koneksi internet
  Future<bool> _hasInternetConnection(List<ConnectivityResult> connectivityResults) async {
    if (connectivityResults.isEmpty || connectivityResults.contains(ConnectivityResult.none)) {
      return false;
    }

    try {
      // Ping ke Google DNS untuk memastikan ada koneksi internet
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  // Update status koneksi
  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionStatusController.add(this.isConnected);
    }
  }

  // Switch manual ke offline mode
  void switchToOfflineMode() {
    if (!_isManualOfflineMode) {
      _isManualOfflineMode = true;
      _connectionStatusController.add(false);
    }
  }

  // Switch manual ke online mode
  void switchToOnlineMode() {
    if (_isManualOfflineMode) {
      _isManualOfflineMode = false;
      _connectionStatusController.add(_isConnected);
    }
  }

  // Toggle mode manual
  void toggleMode() {
    if (_isManualOfflineMode) {
      switchToOnlineMode();
    } else {
      switchToOfflineMode();
    }
  }

  // Cek apakah fitur tersedia dalam mode saat ini
  bool isFeatureAvailable(String feature) {
    if (isOnlineMode) {
      return true; // Semua fitur tersedia dalam online mode
    }
    
    // Dalam offline mode, hanya fitur tertentu yang tersedia
    final allowedOfflineFeatures = [
      'pos',
      'transactions',
      'home',
    ];
    
    return allowedOfflineFeatures.contains(feature.toLowerCase());
  }

  // Get status message untuk UI
  String getStatusMessage() {
    if (_isManualOfflineMode) {
      return 'Mode Offline (Manual)';
    } else if (!_isConnected) {
      return 'Mode Offline (Tidak Ada Koneksi)';
    } else {
      return 'Mode Online';
    }
  }

  // Get status color untuk UI
  String getStatusColor() {
    if (isOnlineMode) {
      return 'green';
    } else {
      return 'orange';
    }
  }

  // Dispose resources
  void dispose() {
    _connectionStatusController.close();
  }
}