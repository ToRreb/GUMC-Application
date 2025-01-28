import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/landing_page.dart';
import 'services/notification_service.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'services/performance_service.dart';
import 'services/analytics_service.dart';
import 'services/cache_service.dart';
import 'widgets/error_boundary.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Test Firebase connection
  try {
    await FirebaseFirestore.instance.collection('test').get();
    print('✅ Firebase connection successful!');
  } catch (e) {
    print('❌ Firebase connection failed: $e');
  }

  // Initialize notification service
  await NotificationService().init();
  
  // Initialize services
  final getIt = GetIt.instance;
  getIt.registerSingleton<ConnectivityService>(ConnectivityService());
  getIt.registerSingleton<PerformanceService>(PerformanceService());
  getIt.registerSingleton<AnalyticsService>(AnalyticsService());
  getIt.registerSingletonAsync<CacheService>(() => CacheService.init());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MaterialApp(
        title: 'GUMC APP',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const LandingPage(),
      ),
    );
  }
} 