import 'package:flutter/material.dart';

class UndistortedCameraView extends StatefulWidget {
  const UndistortedCameraView({super.key});

  @override
  State<UndistortedCameraView> createState() => _UndistortedCameraViewState();
}

class _UndistortedCameraViewState extends State<UndistortedCameraView> {
  bool showOverlay = false;

  void toggleOverlay() {
    setState(() => showOverlay = !showOverlay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Undistorted Camera View')),
            drawer: Drawer(
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      const DrawerHeader(
        decoration: BoxDecoration(color: Colors.blue),
        child: Text('Undistorted Camera Controls', style: TextStyle(color: Colors.white)),
      ),
      ListTile(
        title: const Text("Close Drawer"),
        leading: const Icon(Icons.close),
        onTap: () => Navigator.of(context).pop(),
      ),
      ListTile(
        title: Text(
          showOverlay
              ? "Hide Calibration Overlay"
              : "Show Calibration Overlay",
        ),
        onTap: toggleOverlay,
      ),
    ],
  ),
),

      body: Center(
        child: Stack(
          children: [
            const Center(child: Text('Undistorted Camera View (placeholder)')),
            if (showOverlay)
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.purple, width: 2),
                  ),
                  child: const Center(child: Text("Overlay Box")),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
