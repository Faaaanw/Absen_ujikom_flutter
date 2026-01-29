import 'package:flutter/material.dart';
import 'package:qr_absen/services/api_service.dart';
import 'package:qr_absen/Page/login_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginPage(),
    );
  }
}
