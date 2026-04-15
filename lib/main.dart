import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/di/service_locator.dart';
import 'services/push/firebase_push_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // await Firebase.initializeApp();
  
  // Setup dependency injection
  setupServiceLocator();
  
  // Initialize push notifications
  // await FirebasePushService().initialize();
  
  // Get user role from auth service
  // Get user role from auth service
  final authService = getIt<AuthService>();
  await authService.init();
  final role = await authService.getUserRole();
  final isFirstRun = await authService.isFirstRun();
  
  runApp(DeliveryApp(
    userRole: role,
    isFirstRun: isFirstRun,
  ));
}
