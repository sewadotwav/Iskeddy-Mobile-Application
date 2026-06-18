import 'package:flutter/material.dart';
import 'main_shell.dart';

class IskeddyApp extends StatelessWidget {
  const IskeddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iskeddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        fontFamily: 'ZalandoSansSemiExpanded',
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}