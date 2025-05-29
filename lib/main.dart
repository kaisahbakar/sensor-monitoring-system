import 'package:flutter/material.dart';
import 'login.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';

void main() {
  runApp(const SensorApp());
}

class SensorApp extends StatelessWidget {
  const SensorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Monitoring App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/admin': (context) => AdminDashboard(),
        '/user': (context) => UserDashboard(),
      },
    );
  }
}
