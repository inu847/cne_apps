import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:cne_pos_apps/services/platform_service.dart';

void main() {
  group('PlatformService Tests', () {
    late PlatformService platformService;
    
    setUp(() {
      platformService = PlatformService();
    });
    
    test('PlatformService should be a singleton', () {
      final instance1 = PlatformService();
      final instance2 = PlatformService();
      
      // Both instances should be the same object
      expect(identical(instance1, instance2), true);
    });
    
    test('isWeb should return correct value', () {
      // This will always be false in a Dart VM test environment
      // but we're testing the API works
      expect(platformService.isWeb, kIsWeb);
    });
    
    test('getPlatformName should return a non-empty string', () async {
      final platformName = await platformService.getPlatformName();
      
      expect(platformName, isNotEmpty);
      // In test environment, this will typically be one of the supported platforms
      expect(
        ['android', 'ios', 'windows', 'linux', 'macos', 'fuchsia', 'web', 'unknown'],
        contains(platformName)
      );
    });
    
    test('getTemporaryDir should return a directory', () async {
      final tempDir = await platformService.getTemporaryDir();
      
      // Directory should not be null
      expect(tempDir, isNotNull);
      
      // Path should not be empty
      expect(tempDir.path, isNotEmpty);
    });
    
    test('createTempFile should create a file with the given name', () async {
      final filename = 'test_file.txt';
      final file = await platformService.createTempFile(filename);
      
      // File should not be null
      expect(file, isNotNull);
      
      // Path should contain the filename
      expect(file.path, contains(filename));
    });
    
    test('Platform detection methods should not throw exceptions', () async {
      // These should complete without throwing exceptions
      await expectLater(platformService.isWindows, completes);
      await expectLater(platformService.isLinux, completes);
      await expectLater(platformService.isMacOS, completes);
      await expectLater(platformService.isAndroid, completes);
      await expectLater(platformService.isIOS, completes);
    });
  });
}