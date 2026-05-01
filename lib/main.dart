import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'services/hardware_service.dart';

import 'services/wifi_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HardwareService.init();
  await WifiService.init();
  runApp(const WinnerGameManager());
}

class WinnerGameManager extends StatelessWidget {
  const WinnerGameManager({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Winner Game Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
