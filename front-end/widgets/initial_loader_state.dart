import 'package:flutter/material.dart';
import '../widgets/home_switcher.dart';
import '../widgets/splash_screen.dart';

class InitialLoader extends StatefulWidget {
  const InitialLoader({super.key});

  @override
  State<InitialLoader> createState() => _InitialLoaderState();
}

class _InitialLoaderState extends State<InitialLoader> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();

    // Make sure precache happens *after* first frame
    _initializationFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for the first frame before precaching
    await Future.delayed(Duration.zero);

    await Future.wait([
      precacheImage(const AssetImage('assets/images/logo.png'), context),
      Future.delayed(const Duration(seconds: 3)), // ensures splash shows
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const HomeSwitcher();
        }
        return const SplashScreen();
      },
    );
  }
}
