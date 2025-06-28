# Performance Optimization Guide

## Overview

This document provides recommendations for optimizing the performance of the CNE POS Apps Flutter application, with a particular focus on PDF generation, file operations, and cross-platform compatibility.

## PDF Generation Optimizations

### Current Implementation

The current PDF generation process in `receipt_service.dart` runs on the main thread and may cause UI freezes, especially on less powerful devices. Additionally, the compression of PDF files using `GZipEncoder` adds extra processing time.

### Recommendations

#### 1. Move PDF Generation to Isolates

```dart
Future<Uint8List> generateReceiptPdf(Receipt receipt) async {
  // Use compute to run in a separate isolate
  return await compute(_generatePdfInIsolate, receipt);
}

// This function runs in a separate isolate
Uint8List _generatePdfInIsolate(Receipt receipt) {
  // Current PDF generation logic
  // ...
  return pdfBytes;
}
```

#### 2. Implement Caching for Generated PDFs

```dart
class ReceiptService {
  // Cache for generated PDFs
  final Map<String, Uint8List> _pdfCache = {};
  
  Future<Uint8List> generateReceiptPdf(Receipt receipt) async {
    final cacheKey = receipt.invoiceNumber;
    
    // Check if PDF is already in cache
    if (_pdfCache.containsKey(cacheKey)) {
      return _pdfCache[cacheKey]!;
    }
    
    // Generate PDF
    final pdfBytes = await compute(_generatePdfInIsolate, receipt);
    
    // Cache the result
    _pdfCache[cacheKey] = pdfBytes;
    
    return pdfBytes;
  }
  
  // Method to clear cache when needed
  void clearPdfCache() {
    _pdfCache.clear();
  }
}
```

#### 3. Optimize PDF Compression

```dart
// Only compress PDFs above a certain size threshold
Future<Uint8List> optimizePdfSize(Uint8List pdfBytes) async {
  // Skip compression for small PDFs
  if (pdfBytes.length < 100 * 1024) { // 100 KB threshold
    return pdfBytes;
  }
  
  // For larger PDFs, compress using compute to avoid blocking the main thread
  return await compute(_compressPdf, pdfBytes);
}

Uint8List _compressPdf(Uint8List pdfBytes) {
  final compressedBytes = GZipEncoder().encode(pdfBytes);
  return Uint8List.fromList(compressedBytes ?? pdfBytes);
}
```

#### 4. Lazy Load PDF Resources

```dart
class ReceiptService {
  // Load resources only when needed
  Future<pw.Font> get regularFont async {
    if (_cachedRegularFont == null) {
      _cachedRegularFont = await _loadRegularFont();
    }
    return _cachedRegularFont!;
  }
  
  Future<pw.Font> get boldFont async {
    if (_cachedBoldFont == null) {
      _cachedBoldFont = await _loadBoldFont();
    }
    return _cachedBoldFont!;
  }
  
  // Use these getters in PDF generation
  Future<Uint8List> generateReceiptPdf(Receipt receipt) async {
    // Load resources in parallel
    final font = await regularFont;
    final fontBold = await boldFont;
    
    // Rest of PDF generation logic
  }
}
```

## File Operations Optimizations

### Current Implementation

The current implementation uses a combination of `path_provider` and fallback mechanisms for file operations, which is robust but could be optimized for performance.

### Recommendations

#### 1. Batch File Operations

```dart
Future<void> saveReceiptFiles(Receipt receipt, Uint8List pdfBytes, Uint8List imageBytes) async {
  final tempDir = await platformService.getTemporaryDir();
  final baseFileName = 'receipt_${receipt.invoiceNumber}';
  
  // Create all files in parallel
  await Future.wait([
    File('${tempDir.path}/$baseFileName.pdf').writeAsBytes(pdfBytes),
    File('${tempDir.path}/$baseFileName.png').writeAsBytes(imageBytes),
    File('${tempDir.path}/$baseFileName.json').writeAsString(jsonEncode(receipt)),
  ]);
}
```

#### 2. Implement File Operation Queue

```dart
class FileOperationQueue {
  final Queue<Future Function()> _queue = Queue();
  bool _processing = false;
  
  Future<T> enqueue<T>(Future<T> Function() operation) async {
    final completer = Completer<T>();
    
    _queue.add(() async {
      try {
        final result = await operation();
        completer.complete(result);
        return result;
      } catch (e) {
        completer.completeError(e);
        rethrow;
      }
    });
    
    _processQueue();
    return completer.future;
  }
  
  Future<void> _processQueue() async {
    if (_processing || _queue.isEmpty) return;
    
    _processing = true;
    try {
      while (_queue.isNotEmpty) {
        final operation = _queue.removeFirst();
        await operation();
      }
    } finally {
      _processing = false;
    }
  }
}

// Usage
final fileQueue = FileOperationQueue();

// Enqueue file operations
await fileQueue.enqueue(() => file.writeAsBytes(bytes));
```

#### 3. Optimize Directory Creation

```dart
Future<Directory> ensureDirectoryExists(String path) async {
  final directory = Directory(path);
  
  // Check if directory exists before creating
  if (await directory.exists()) {
    return directory;
  }
  
  // Create directory if it doesn't exist
  return await directory.create(recursive: true);
}
```

## Image Handling Optimizations

### Current Implementation

The current implementation loads and caches logo images, but there's room for optimization in terms of image resizing and format conversion.

### Recommendations

#### 1. Resize Images Before Saving

```dart
Future<Uint8List> optimizeLogoImage(Uint8List originalBytes) async {
  // Use compute to run in a separate isolate
  return await compute(_resizeImage, originalBytes);
}

Uint8List _resizeImage(Uint8List originalBytes) {
  // Decode image
  final image = img.decodeImage(originalBytes);
  if (image == null) return originalBytes;
  
  // Skip resizing if image is already small
  if (image.width <= 300 && image.height <= 300) {
    return originalBytes;
  }
  
  // Resize image to reasonable dimensions for a receipt
  final resized = img.copyResize(
    image,
    width: image.width > 300 ? 300 : image.width,
    height: image.height > 300 ? 300 : image.height,
  );
  
  // Encode as PNG with reduced quality
  return Uint8List.fromList(img.encodePng(resized, level: 6));
}
```

#### 2. Implement Memory-Efficient Image Cache

```dart
class ImageCache {
  final Map<String, Uint8List> _cache = {};
  final int _maxSize;
  int _currentSize = 0;
  
  ImageCache({int maxSizeInBytes = 10 * 1024 * 1024}) : _maxSize = maxSizeInBytes;
  
  bool has(String key) => _cache.containsKey(key);
  
  Uint8List? get(String key) => _cache[key];
  
  void set(String key, Uint8List bytes) {
    // Remove existing entry if present
    if (_cache.containsKey(key)) {
      _currentSize -= _cache[key]!.length;
      _cache.remove(key);
    }
    
    // Check if new image would exceed cache size
    if (_currentSize + bytes.length > _maxSize) {
      _evictUntilFits(bytes.length);
    }
    
    // Add to cache
    _cache[key] = bytes;
    _currentSize += bytes.length;
  }
  
  void _evictUntilFits(int requiredSize) {
    // Simple LRU could be implemented here
    // For now, just clear enough entries
    final entries = _cache.entries.toList();
    entries.sort((a, b) => a.value.length.compareTo(b.value.length));
    
    for (final entry in entries) {
      if (_currentSize + requiredSize <= _maxSize) break;
      
      _currentSize -= entry.value.length;
      _cache.remove(entry.key);
    }
  }
  
  void clear() {
    _cache.clear();
    _currentSize = 0;
  }
}
```

## UI Rendering Optimizations

### Current Implementation

The current implementation may rebuild widgets unnecessarily and doesn't use const constructors where possible.

### Recommendations

#### 1. Use const Constructors

```dart
// Before
return Container(
  padding: EdgeInsets.all(8.0),
  child: Text('Hello'),
);

// After
return const Container(
  padding: EdgeInsets.all(8.0),
  child: Text('Hello'),
);
```

#### 2. Implement shouldRepaint for Custom Painters

```dart
class ReceiptPainter extends CustomPainter {
  final Receipt receipt;
  
  ReceiptPainter(this.receipt);
  
  @override
  void paint(Canvas canvas, Size size) {
    // Painting logic
  }
  
  @override
  bool shouldRepaint(ReceiptPainter oldDelegate) {
    // Only repaint if receipt data changed
    return receipt.invoiceNumber != oldDelegate.receipt.invoiceNumber;
  }
}
```

#### 3. Use RepaintBoundary for Complex UI

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // Header that changes frequently
        HeaderWidget(),
        
        // Complex content that rarely changes
        RepaintBoundary(
          child: ReceiptPreview(receipt: widget.receipt),
        ),
      ],
    ),
  );
}
```

## Memory Management

### Current Implementation

The current implementation caches some resources but doesn't have a comprehensive memory management strategy.

### Recommendations

#### 1. Implement Proper Resource Disposal

```dart
class _ReceiptScreenState extends State<ReceiptScreen> {
  File? _pdfFile;
  
  @override
  void dispose() {
    // Clean up temporary files
    _cleanupTempFiles();
    super.dispose();
  }
  
  Future<void> _cleanupTempFiles() async {
    try {
      if (_pdfFile != null && await _pdfFile!.exists()) {
        await _pdfFile!.delete();
      }
    } catch (e) {
      print('Error cleaning up temp files: $e');
    }
  }
}
```

#### 2. Implement Memory Monitoring

```dart
class MemoryMonitor {
  static const int _warningThresholdBytes = 100 * 1024 * 1024; // 100 MB
  
  static Future<void> checkMemoryUsage() async {
    try {
      // This is a simplified example - actual implementation would depend on platform
      final memoryInfo = await _getMemoryInfo();
      
      if (memoryInfo > _warningThresholdBytes) {
        // Take action to reduce memory usage
        await _reduceMemoryUsage();
      }
    } catch (e) {
      print('Error checking memory usage: $e');
    }
  }
  
  static Future<int> _getMemoryInfo() async {
    // Platform-specific implementation
    return 0; // Placeholder
  }
  
  static Future<void> _reduceMemoryUsage() async {
    // Clear caches
    imageCache.clear();
    // Clear other app-specific caches
  }
}
```

## Conclusion

Implementing these performance optimizations will significantly improve the responsiveness and efficiency of the CNE POS Apps, particularly for resource-intensive operations like PDF generation and image processing. The key principles to follow are:

1. Move heavy computations off the main thread using isolates
2. Implement efficient caching strategies
3. Optimize file and image operations
4. Reduce unnecessary UI rebuilds
5. Implement proper resource management

These optimizations should be implemented incrementally, with performance testing after each change to measure the impact and ensure that no regressions are introduced.