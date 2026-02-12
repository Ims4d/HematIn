import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'providers/theme_provider.dart';
import 'viewmodels/summary_viewmodel.dart';
import 'viewmodels/expense_list_viewmodel.dart';
import 'viewmodels/visualization_viewmodel.dart';
import 'viewmodels/add_expense_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  // Initialize date formatting
  await initializeDateFormatting('id_ID', null);

  // Initialize services
  await PreferencesService.instance.initialize();
  await NotificationService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SummaryViewModel()),
        ChangeNotifierProvider(create: (_) => ExpenseListViewModel()),
        ChangeNotifierProvider(create: (_) => VisualizationViewModel()),
        ChangeNotifierProvider(create: (_) => AddExpenseViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Pengelolaan Pengeluaran',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const MainNavigation(),
        );
      },
    );
  }
}
