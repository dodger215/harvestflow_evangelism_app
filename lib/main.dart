import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harvestflow/theme.dart';
import 'package:harvestflow/screens/home_screen.dart';

// Database imports
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqlite_api.dart' 
    show databaseFactory; // so we can override factory
// Uncomment if you want web support
// import 'package:sqflite_web/sqflite_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    DatabaseFactory? databaseFactoryWeb;
    databaseFactory = databaseFactoryWeb;
  } else {
    // 🔹 Desktop (Windows, Linux, macOS)
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SoulWinning',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
