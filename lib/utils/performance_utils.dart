import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<int>> _durations = {};

  void startTimer(String operation) {
    if (kDebugMode) {
      _startTimes[operation] = DateTime.now();
    }
  }

  void endTimer(String operation) {
    if (kDebugMode && _startTimes.containsKey(operation)) {
      final duration = DateTime.now().difference(_startTimes[operation]!);
      _durations.putIfAbsent(operation, () => []).add(duration.inMilliseconds);
      _startTimes.remove(operation);
      
      // Log if operation takes too long
      if (duration.inMilliseconds > 16) { // 60fps = 16ms per frame
        debugPrint('⚠️ Slow operation: $operation took ${duration.inMilliseconds}ms');
      }
    }
  }

  void logStats() {
    if (kDebugMode) {
      _durations.forEach((operation, durations) {
        final avg = durations.reduce((a, b) => a + b) / durations.length;
        final max = durations.reduce((a, b) => a > b ? a : b);
        debugPrint('📊 $operation: avg=${avg.toStringAsFixed(1)}ms, max=${max}ms, count=${durations.length}');
      });
    }
  }

  void clearStats() {
    _durations.clear();
    _startTimes.clear();
  }
}

class PerformantBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) builder;
  final String? debugLabel;

  const PerformantBuilder({
    Key? key,
    required this.builder,
    this.debugLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && debugLabel != null) {
      PerformanceMonitor().startTimer('build_$debugLabel');
    }
    
    final widget = RepaintBoundary(
      child: builder(context),
    );
    
    if (kDebugMode && debugLabel != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PerformanceMonitor().endTimer('build_$debugLabel');
      });
    }
    
    return widget;
  }
}

class DebouncedCallback {
  final Duration delay;
  Timer? _timer;

  DebouncedCallback({this.delay = const Duration(milliseconds: 300)});

  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class ThrottledCallback {
  final Duration interval;
  DateTime? _lastCall;

  ThrottledCallback({this.interval = const Duration(milliseconds: 100)});

  void call(VoidCallback callback) {
    final now = DateTime.now();
    if (_lastCall == null || now.difference(_lastCall!) >= interval) {
      _lastCall = now;
      callback();
    }
  }
}

mixin PerformanceMixin<T extends StatefulWidget> on State<T> {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _monitor.startTimer('${widget.runtimeType}_initState');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _monitor.endTimer('${widget.runtimeType}_initState');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      _monitor.startTimer('${widget.runtimeType}_build');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _monitor.endTimer('${widget.runtimeType}_build');
      });
    }
    return buildWidget(context);
  }

  Widget buildWidget(BuildContext context);
}

class OptimizedListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListView({
    Key? key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          key: ValueKey(index),
          child: children[index],
        );
      },
    );
  }
}