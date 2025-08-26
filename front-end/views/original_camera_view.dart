import 'package:flutter/material.dart';

class OriginalCameraView extends StatefulWidget {
  const OriginalCameraView({super.key});

  @override
  State<OriginalCameraView> createState() => _OriginalCameraViewState();
}

class _OriginalCameraViewState extends State<OriginalCameraView> {
  bool showGrid = false;

  void toggleGrid() {
    setState(() => showGrid = !showGrid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Original Camera View')),
            drawer: Drawer(
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      const DrawerHeader(
        decoration: BoxDecoration(color: Colors.blue),
        child: Text('Original Camera Controls', style: TextStyle(color: Colors.white)),
      ),
      ListTile(
        title: const Text("Close Drawer"),
        leading: const Icon(Icons.close),
        onTap: () => Navigator.of(context).pop(),
      ),
      ListTile(
        title: Text(showGrid ? "Hide Grid Overlay" : "Show Grid Overlay"),
        onTap: toggleGrid,
      ),
    ],
  ),
),

      body: Center(
        child: Stack(
          children: [
            const Center(child: Text('Original Camera View (placeholder)')),
            if (showGrid)
              CustomPaint(
                size: const Size(double.infinity, double.infinity),
                painter: GridPainter(),
              ),
          ],
        ),
      ),
    );
  }
}

// Optional: simple grid overlay for demo purposes
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.2)
          ..strokeWidth = 0.5;

    const step = 40.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
