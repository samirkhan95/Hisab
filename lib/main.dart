import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab/core/router.dart';
import 'package:hisab/core/theme.dart';
import 'package:hisab/core/providers/theme_provider.dart';
import 'package:hisab/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Gold Standard for BakiPay)
  await Firebase.initializeApp();

  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Notification initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: HisabApp(),
    ),
  );
}

class HisabApp extends ConsumerWidget {
  const HisabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'BakiPay',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
