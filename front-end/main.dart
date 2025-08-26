import 'package:flutter/material.dart';
import 'widgets/initial_loader_state.dart';

void main() {
  runApp(const BrickMMOApp());
}

class BrickMMOApp extends StatelessWidget {
  const BrickMMOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrickMMO APP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const InitialLoader(),
    );
  }
}
