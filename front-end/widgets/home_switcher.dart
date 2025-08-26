import 'package:flutter/material.dart';
import '../views/city_grid_view.dart';
import '../views/pixy_blocks_view.dart';
import '../views/original_camera_view.dart';
import '../views/undistorted_camera_view.dart';

class HomeSwitcher extends StatefulWidget {
  const HomeSwitcher({super.key});

  @override
  State<HomeSwitcher> createState() => _HomeSwitcherState();
}

class _HomeSwitcherState extends State<HomeSwitcher> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    LazyLoadWidget(child: PixyBlocksView()),
    LazyLoadWidget(child: CityGridView()),
    LazyLoadWidget(child: OriginalCameraView()),
    LazyLoadWidget(child: UndistortedCameraView()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BrickMMO + Pixy Viewer')),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.traffic),
            label: 'Pixy Blocks',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'City Grid'),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Original Camera View',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_enhance),
            label: 'Undistorted Camera View',
          ),
        ],
      ),
    );
  }
}

class LazyLoadWidget extends StatefulWidget {
  final Widget child;

  const LazyLoadWidget({super.key, required this.child});

  @override
  // ignore: library_private_types_in_public_api
  _LazyLoadWidgetState createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  bool _shouldLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_shouldLoad && mounted) {
        setState(() => _shouldLoad = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _shouldLoad
        ? widget.child
        : const Center(child: CircularProgressIndicator());
  }
}
