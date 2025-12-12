import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/media_service.dart';
import 'services/notification_service.dart';
import 'services/alarm_service.dart';
import 'services/home_widget_service.dart';
import 'providers/app_provider.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive storage
  await StorageService.init();
  
  // Initialize Media Service (Hive boxes for photos/videos/screenshots)
  await MediaService.init();
  
  // Initialize Notification Service for habit reminders
  await NotificationService().initialize();
  
  // Initialize Alarm Service for Plan 2026 reminders
  await AlarmService().initialize();
  
  // Initialize Home Widget Service
  await HomeWidgetService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..loadData(),
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'Review 2025 & Plan 2026',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
