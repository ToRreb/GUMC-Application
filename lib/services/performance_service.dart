import 'package:firebase_performance/firebase_performance.dart';

class PerformanceService {
  final FirebasePerformance _performance = FirebasePerformance.instance;
  
  Future<T> trackOperation<T>({
    required String name,
    required Future<T> Function() operation,
    Map<String, String>? attributes,
  }) async {
    final trace = await _performance.newTrace(name);
    await trace.start();
    
    if (attributes != null) {
      attributes.forEach((key, value) {
        trace.putAttribute(key, value);
      });
    }

    try {
      final result = await operation();
      trace.putAttribute('success', 'true');
      return result;
    } catch (e) {
      trace.putAttribute('success', 'false');
      trace.putAttribute('error', e.toString());
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  Trace startTrace(String name) {
    return _performance.newTrace(name);
  }
} 