import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/home_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();

  await authProvider.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,
      child: const HistoriaApp(),
    ),
  );
}

class HistoriaApp extends StatelessWidget {
  const HistoriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HISTORIA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeRouter(),
    );
  }
}
