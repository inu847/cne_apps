import 'dart:io' show Directory, File;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:path_provider/path_provider.dart';

/// A service that provides platform-specific functionality and handles platform detection
/// in a way that works across all platforms including web.
class PlatformService {
  // Singleton instance
  static final PlatformService _instance = PlatformService._internal();
  
  // Factory constructor to return the singleton instance
  factory PlatformService() => _instance;
  
  // Private constructor
  PlatformService._internal();
  
  // Cache for temporary directory
  Directory? _tempDir;
  
  /// Determines if the app is running on web platform
  bool get isWeb => kIsWeb;
  
  /// Determines the current platform in a safe way that works on all platforms
  Future<String> getPlatformName() async {
    if (kIsWeb) {
      return 'web';
    }
    
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'android';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return 'ios';
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        return 'windows';
      } else if (defaultTargetPlatform == TargetPlatform.linux) {
        return 'linux';
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        return 'macos';
      } else if (defaultTargetPlatform == TargetPlatform.fuchsia) {
        return 'fuchsia';
      }
    } catch (e) {
      print('Error detecting platform: $e');
    }
    
    return 'unknown';
  }
  
  /// Gets a temporary directory that works across all platforms
  Future<Directory> getTemporaryDir() async {
    if (_tempDir != null) {
      return _tempDir!;
    }
    
    try {
      if (kIsWeb) {
        // Web doesn't support file system like native platforms
        print('Web platform detected, using fallback directory');
        _tempDir = Directory('temp');
        return _tempDir!;
      }
      
      try {
        _tempDir = await getTemporaryDirectory();
        return _tempDir!;
      } catch (pathError) {
        print('Error with path_provider: $pathError');
        
        try {
          if (defaultTargetPlatform == TargetPlatform.windows) {
            // Fallback for Windows
            final String tempPath = const String.fromEnvironment('TEMP', defaultValue: 'C:\\Windows\\Temp');
            _tempDir = Directory(tempPath);
            print('Using Windows fallback directory: $tempPath');
          } else if (defaultTargetPlatform == TargetPlatform.linux) {
            // Fallback for Linux
            _tempDir = Directory('/tmp');
            print('Using Linux fallback directory: /tmp');
          } else {
            // General fallback
            _tempDir = Directory('temp');
            print('Using general fallback directory: temp');
            if (!await _tempDir!.exists()) {
              await _tempDir!.create(recursive: true);
            }
          }
        } catch (platformError) {
          print('Error detecting platform: $platformError');
          // Safest fallback if platform detection fails
          _tempDir = Directory('temp');
          print('Using safe fallback directory after platform detection error: temp');
          if (!await _tempDir!.exists()) {
            await _tempDir!.create(recursive: true);
          }
        }
      }
    } catch (e) {
      print('Critical error in temp directory initialization: $e');
      // Last resort fallback if all methods fail
      _tempDir = Directory('temp');
      try {
        if (!await _tempDir!.exists()) {
          await _tempDir!.create(recursive: true);
        }
      } catch (e) {
        print('Failed to create fallback directory: $e');
      }
    }
    
    return _tempDir!;
  }
  
  /// Creates a temporary file with the given filename
  Future<File> createTempFile(String filename) async {
    final tempDir = await getTemporaryDir();
    return File('${tempDir.path}/$filename');
  }
  
  /// Safely checks if running on Windows
  Future<bool> get isWindows async {
    if (kIsWeb) return false;
    try {
      return defaultTargetPlatform == TargetPlatform.windows;
    } catch (e) {
      print('Error checking if platform is Windows: $e');
      return false;
    }
  }
  
  /// Safely checks if running on Linux
  Future<bool> get isLinux async {
    if (kIsWeb) return false;
    try {
      return defaultTargetPlatform == TargetPlatform.linux;
    } catch (e) {
      print('Error checking if platform is Linux: $e');
      return false;
    }
  }
  
  /// Safely checks if running on macOS
  Future<bool> get isMacOS async {
    if (kIsWeb) return false;
    try {
      return defaultTargetPlatform == TargetPlatform.macOS;
    } catch (e) {
      print('Error checking if platform is macOS: $e');
      return false;
    }
  }
  
  /// Safely checks if running on Android
  Future<bool> get isAndroid async {
    if (kIsWeb) return false;
    try {
      return defaultTargetPlatform == TargetPlatform.android;
    } catch (e) {
      print('Error checking if platform is Android: $e');
      return false;
    }
  }
  
  /// Safely checks if running on iOS
  Future<bool> get isIOS async {
    if (kIsWeb) return false;
    try {
      return defaultTargetPlatform == TargetPlatform.iOS;
    } catch (e) {
      print('Error checking if platform is iOS: $e');
      return false;
    }
  }
}