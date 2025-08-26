import 'dart:async';
import 'package:brickmmo_pixy_viewer/models/block_data.dart';
import 'package:flutter/material.dart';
import 'package:brickmmo_pixy_viewer/services/crypto_service.dart';
// import 'package:brickmmo_pixy_viewer/models/block_data.dart';
import 'package:brickmmo_pixy_viewer/services/map_service.dart';
import 'package:brickmmo_pixy_viewer/services/pixy_service.dart';
import 'package:brickmmo_pixy_viewer/services/block_tracker.dart';
import 'package:brickmmo_pixy_viewer/widgets/grid_cell.dart';
import 'package:brickmmo_pixy_viewer/widgets/tile_info_modal.dart';
import 'package:brickmmo_pixy_viewer/widgets/hover_overlay.dart';
import 'package:brickmmo_pixy_viewer/widgets/tracked_blocks_panel.dart';

/// Main view displaying the city grid with interactive blocks
/// Coordinates all services and provides user interface for block tracking
class CityGridView extends StatefulWidget {
  const CityGridView({super.key});

  @override
  State<CityGridView> createState() => _CityGridViewState();
}

class _CityGridViewState extends State<CityGridView>
    with TickerProviderStateMixin {
  // Service instances for managing different aspects of the application
  late final MapService _mapService; // Handles map data and grid information
  late final PixyService
  _pixyService; // Manages Pixy camera data and block detection
  late final BlockTracker _blockTracker; // Handles block tracking and animation
  late final CryptoService _cryptoService; // Manages cryptocurrency operations

  // UI state variables
  double _cellSize = 30.0; // Current size of grid cells in pixels
  bool _isActive = true; // Controls whether background processes are running
  String? _hoveredCellKey; // Track which cell is currently hovered for overlay
  OverlayEntry? _currentOverlayEntry; // Reference to the current hover overlay
  bool _isCapturingRoadBlocks =
      false; // Flag for block capture operation in progress
  // Map<String, BlockData> _capturedBlocks =
  //     {}; // Stores blocks captured during registration

  // Tracked blocks panel state
  bool _showTrackedBlocksPanel = false; // Controls visibility of tracking panel
  OverlayEntry?
  _trackedBlocksPanelEntry; // Reference to the tracking panel overlay

  @override
  void initState() {
    super.initState();
    _initializeServices(); // Set up all service instances
    _isActive = true; // Enable background processes
    loadMapData(); // Load initial map data
  }

  /// Initializes all service instances with proper dependencies
  Future<void> _initializeServices() async {
    _mapService = MapService();
    _pixyService = PixyService(
      _mapService,
    ); // Pass map service for color checking
    _blockTracker = BlockTracker();
    _cryptoService = CryptoService();

    await _cryptoService.init(); // Initialize crypto service
    _blockTracker.init(this); // Provide ticker provider for animations

    // Add listener for block tracker changes to update UI
    _blockTracker.addListener(_onBlockTrackerChanged);
  }

  /// Callback when block tracker state changes (new blocks, movement, etc.)
  void _onBlockTrackerChanged() {
    if (_showTrackedBlocksPanel && mounted) {
      setState(() {
        // Force UI update when tracked blocks change
        _updateTrackedBlocksPanel();
      });
    }
  }

  @override
  void dispose() {
    // Clean up resources and stop background processes
    _isActive = false;
    _hideOverlay();
    _hideTrackedBlocksPanel();
    _blockTracker.removeListener(_onBlockTrackerChanged);
    _blockTracker.dispose();
    _pixyService.dispose();
    super.dispose();
  }

  /// Loads map data from API and starts Pixy overlay updates
  Future<void> loadMapData() async {
    await _mapService.loadMapData();
    if (mounted) setState(() {}); // Update UI with new map data
    startPixyOverlay(); // Start continuous Pixy data updates
  }

  /// Starts the continuous Pixy overlay update loop
  void startPixyOverlay() {
    _pixyService.startOverlayLoop(
      isActive: () => _isActive && mounted, // Check if still active and mounted
      onUpdate: () {
        if (mounted) setState(() {}); // Update UI with new overlay data
        // Monitor all tracked blocks against current Pixy data
        // _blockTracker.monitorAllBlocks(_pixyService.pixyOverlayColors);
        _blockTracker.monitorAllBlocks(_pixyService.pixyBlockData);
      },
    );
  }

  /// Captures blocks from Pixy cameras for 5 seconds and registers them
  Future<void> captureRoadBlocksFor5Seconds() async {
    if (_isCapturingRoadBlocks)
      return; // Prevent multiple simultaneous captures

    setState(() => _isCapturingRoadBlocks = true);

    try {
      // Capture blocks for 5 seconds duration
      final captured = await _pixyService.captureBlocksForDuration(
        const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          // _capturedBlocks = captured;
          _blockTracker.registerCapturedBlocks(
            captured,
          ); // Register with tracker
          _isCapturingRoadBlocks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturingRoadBlocks = false);
      }
      print('Error capturing blocks: $e');
    }
  }

  /// Sends all registered blocks to the backend API
  Future<void> sendBlocksToBackend() async {
    _blockTracker.isSendingToBackend = true;
    // if (mounted) setState(() {}); // Update UI to reflect sending state
    // await Future.delayed(const Duration(milliseconds: 100)); // Brief delay
    // if (mounted) setState(() {}); // Ensure UI updates before sending
    await _blockTracker.sendBlocksToBackend();
    // var result = await _blockTracker.sendBlocksToBackend();
    // print(result);
  }

  /// Toggles the tracked blocks panel visibility
  void _toggleTrackedBlocksPanel() {
    setState(() {
      _showTrackedBlocksPanel = !_showTrackedBlocksPanel;
      if (_showTrackedBlocksPanel) {
        // _showTrackedBlocksPanel();
        _showTrackedBlocksPanelMethod(); // Call the renamed method
      } else {
        _hideTrackedBlocksPanel();
      }
    });
  }

  /// Displays the tracked blocks panel as an overlay
  void _showTrackedBlocksPanelMethod() {
    // Renamed method
    _hideTrackedBlocksPanel(); // Remove any existing panel first

    _trackedBlocksPanelEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            // left: 16, // Position from left edge
            right: 16, // Position from right edge
            top: 80, // Position below app bar
            child: TrackedBlocksPanel(
              blockTracker: _blockTracker,
              onClose: _toggleTrackedBlocksPanel,
            ),
          ),
    );

    Overlay.of(context).insert(_trackedBlocksPanelEntry!);
  }

  // /// Displays the tracked blocks panel as an overlay
  // void _showTrackedBlocksPanel() {
  //   _hideTrackedBlocksPanel(); // Remove any existing panel first

  //   _trackedBlocksPanelEntry = OverlayEntry(
  //     builder:
  //         (context) => Positioned(
  //           left: 16, // Position from left edge
  //           top: 80, // Position below app bar
  //           child: TrackedBlocksPanel(
  //             blockTracker: _blockTracker,
  //             onClose: _toggleTrackedBlocksPanel,
  //           ),
  //         ),
  //   );

  //   Overlay.of(context).insert(_trackedBlocksPanelEntry!);
  // }

  /// Hides and removes the tracked blocks panel
  void _hideTrackedBlocksPanel() {
    _trackedBlocksPanelEntry?.remove();
    _trackedBlocksPanelEntry = null;
  }

  /// Builds the navigation drawer with all control options
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer header with title
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text("Controls", style: TextStyle(color: Colors.white)),
          ),

          // Drawer control items
          _buildCloseDrawerItem(),
          _buildTrackedBlocksPanelItem(),
          _buildCameraTintItem(
            "Camera 1 Tint",
            _mapService.cameraOneTint,
            toggleCameraOneTint,
          ),
          _buildCameraTintItem(
            "Camera 2 Tint",
            _mapService.cameraTwoTint,
            toggleCameraTwoTint,
          ),
          _buildRouteToggleItem(
            "Route 0",
            _pixyService.toggleRoute0,
            setToggleRoute0,
          ),
          _buildRouteToggleItem(
            "Route 1",
            _pixyService.toggleRoute1,
            setToggleRoute1,
          ),
          const Divider(),
          _buildMapScaleControl(),
          const Divider(),
          _buildBlockCaptureItem(),
          _buildSendToBackendItem(),
          const Divider(),
          ..._buildSignatureToggleItems(),
          const Divider(),
          ..._buildCameraToggleItems(),
          const Divider(),

          // Block filter toggles
          _buildBlockFilterToggleItem(
            "Show Blocks on Road",
            _pixyService.showBlocksOnRoad,
            (val) => setState(() {
              _pixyService.showBlocksOnRoad = val;
              _pixyService.fetchPixyOverlay();
            }),
          ),
          _buildBlockFilterToggleItem(
            "Show Blocks on Track",
            _pixyService.showBlocksOnTrack,
            (val) => setState(() {
              _pixyService.showBlocksOnTrack = val;
              _pixyService.fetchPixyOverlay();
            }),
          ),
          _buildBlockFilterToggleItem(
            "Show Blocks on Plain",
            _pixyService.showBlocksOnPlain,
            (val) => setState(() {
              _pixyService.showBlocksOnPlain = val;
              _pixyService.fetchPixyOverlay();
            }),
          ),
        ],
      ),
    );
  }

  /// Drawer item for closing the drawer
  Widget _buildCloseDrawerItem() {
    return ListTile(
      title: const Text("Close Drawer"),
      leading: const Icon(Icons.close),
      onTap: () => Navigator.of(context).pop(),
    );
  }

  /// Drawer item for toggling tracked blocks panel
  Widget _buildTrackedBlocksPanelItem() {
    return ListTile(
      leading: Icon(
        _showTrackedBlocksPanel ? Icons.visibility_off : Icons.visibility,
      ),
      title: Text(
        _showTrackedBlocksPanel ? "Hide Tracked Blocks" : "Show Tracked Blocks",
      ),
      onTap: _toggleTrackedBlocksPanel,
    );
  }

  /// Drawer item for camera tint controls
  Widget _buildCameraTintItem(
    String title,
    bool isEnabled,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(isEnabled ? "Disable $title" : "Enable $title"),
      onTap: onTap,
    );
  }

  /// Drawer item for route toggle controls
  Widget _buildRouteToggleItem(
    String route,
    bool isEnabled,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(isEnabled ? "Disable $route" : "Enable $route"),
      onTap: onTap,
    );
  }

  /// Slider control for adjusting map cell size
  Widget _buildMapScaleControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Map Scale (Cell Size)",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _cellSize,
            min: 10.0,
            max: 60.0,
            divisions: 50,
            label: _cellSize.round().toString(),
            onChanged: (newValue) {
              setState(() {
                _cellSize = newValue;
                _blockTracker.setCellSize(
                  newValue,
                ); // Update tracker with new size
              });
            },
          ),
        ],
      ),
    );
  }

  /// Drawer item for capturing blocks
  Widget _buildBlockCaptureItem() {
    return ListTile(
      leading: const Icon(Icons.location_searching),
      title: Text(
        _isCapturingRoadBlocks
            ? "Capturing Blocks..."
            : "Register Road Blocks (5s)",
      ),
      onTap: _isCapturingRoadBlocks ? null : captureRoadBlocksFor5Seconds,
    );
  }

  /// Drawer item for sending blocks to backend
  Widget _buildSendToBackendItem() {
    return ListTile(
      leading: const Icon(Icons.cloud_upload),
      title: const Text("Send to Backend"),
      onTap: sendBlocksToBackend,
      // _blockTracker.isSendingToBackend
      //     ? () {}
      //     : sendBlocksToBackend, // Disable if already sending
    );
  }

  /// Builds toggle items for signature filtering
  List<Widget> _buildSignatureToggleItems() {
    return [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          "Toggle Signatures",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      for (int sig = 1; sig <= 4; sig++)
        ListTile(
          title: Text(
            _pixyService.disabledSignatures.contains(sig)
                ? "Enable Signature $sig"
                : "Disable Signature $sig",
          ),
          onTap: () => _toggleSignature(sig),
        ),
    ];
  }

  /// Builds toggle items for camera filtering
  List<Widget> _buildCameraToggleItems() {
    return [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          "Toggle Cameras",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      for (var cam in [
        'PI-CAMERA 1: ',
        'PI-CAMERA 2: ',
        'PC-CAMERA 1: ',
        'PC-CAMERA 2: ',
      ])
        ListTile(
          title: Text(
            _pixyService.disabledCameras.contains(cam)
                ? "Enable $cam"
                : "Disable $cam",
          ),
          onTap: () => _toggleCamera(cam),
        ),
    ];
  }

  /// Switch item for block filter toggles
  SwitchListTile _buildBlockFilterToggleItem(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  /// Toggles signature filtering
  void _toggleSignature(int sig) {
    setState(() {
      if (_pixyService.disabledSignatures.contains(sig)) {
        _pixyService.disabledSignatures.remove(sig);
      } else {
        _pixyService.disabledSignatures.add(sig);
      }
    });
  }

  /// Toggles camera filtering
  void _toggleCamera(String cam) {
    setState(() {
      if (_pixyService.disabledCameras.contains(cam)) {
        _pixyService.disabledCameras.remove(cam);
      } else {
        _pixyService.disabledCameras.add(cam);
      }
    });
  }

  /// Toggles camera 1 tint effect
  void toggleCameraOneTint() {
    setState(() {
      _mapService.toggleCameraOneTint();
      loadMapData(); // Reload map to apply tint changes
    });
  }

  /// Toggles camera 2 tint effect
  void toggleCameraTwoTint() {
    setState(() {
      _mapService.toggleCameraTwoTint();
      loadMapData(); // Reload map to apply tint changes
    });
  }

  /// Toggles route 0 availability
  void setToggleRoute0() {
    setState(() {
      _pixyService.setToggleRoute0(!_pixyService.toggleRoute0);
    });
  }

  /// Toggles route 1 availability
  void setToggleRoute1() {
    setState(() {
      _pixyService.setToggleRoute1(!_pixyService.toggleRoute1);
    });
  }

  /// Main build method for the grid view
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map Viewer")),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Main grid content
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: List.generate(_mapService.maxY, (y) {
                  return Row(
                    children: List.generate(_mapService.maxX, (x) {
                      final cellKey = '$x,$y';
                      return GridCell(
                        x: x,
                        y: y,
                        cellSize: _cellSize,
                        baseColor: _mapService.getCellColor(x, y),
                        overlayColor: _pixyService.pixyOverlayColors[cellKey],
                        isHovered: _hoveredCellKey == cellKey,
                        onHover:
                            (position) =>
                                _showOverlay(context, cellKey, position),
                        onHoverExit: _hideOverlay,
                        onTap: () => _showTileModal(context, cellKey),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),

          /*
          // Tracked blocks panel overlay
          if (_showTrackedBlocksPanel)
            Positioned(
              left: 16,
              top: 80,
              child: TrackedBlocksPanel(
                blockTracker: _blockTracker,
                onClose: _toggleTrackedBlocksPanel,
              ),
            ),
            */
        ],
      ),

      // Floating action button for quick access to tracking panel
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleTrackedBlocksPanel,
        tooltip: 'Tracked Blocks',
        child: Icon(_showTrackedBlocksPanel ? Icons.list : Icons.list_alt),
        mini: true,
      ),
    );
  }

  /// Shows hover overlay with cell information
  void _showOverlay(BuildContext context, String cellKey, Offset position) {
    _hideOverlay();
    setState(() => _hoveredCellKey = cellKey);

    _currentOverlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            left: position.dx + 10,
            top: position.dy + 10,
            child: IgnorePointer(
              child: Material(
                color: Colors.transparent,
                child: HoverOverlay(
                  cellKey: cellKey,
                  baseColor: _mapService.getCellColorFromKey(cellKey),
                  overlayColor: _pixyService.getOverlayColorFromKey(cellKey),
                  registeredBlockData: _blockTracker.getBlockAtCell(cellKey),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_currentOverlayEntry!);
  }

  /// Hides the hover overlay
  void _hideOverlay() {
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
    setState(() => _hoveredCellKey = null);
  }

  /// Updates the tracked blocks panel (triggers rebuild)
  void _updateTrackedBlocksPanel() {
    // This forces the panel to rebuild with updated data
    _hideTrackedBlocksPanel();
    if (_showTrackedBlocksPanel) {
      // _showTrackedBlocksPanel();
      _showTrackedBlocksPanelMethod(); // Call the renamed method
      // For each tracked block, print its key and data.
      _blockTracker.trackedBlocks.forEach((key, block) {
        // Don't use print in production; use a logging framework instead.
        // Example: Logger().info('Tracked block: $key, $block');
        if (block is BlockData) {
          print('Tracked block: $key');
          print('  camera: ${block.camera}');
          print('  x: ${block.rawX}');
          print('  y: ${block.rawY}');
          print('  color: ${block.signature}');
          print('  cell: ${block.cell}'); // Add other relevant fields as needed
        } else {
          print('Tracked block: $key, $block');
        }
        // print('Tracked block: $key, $block');
      });
    }
  }

  /// Shows detailed tile information modal
  void _showTileModal(BuildContext context, String cellKey) {
    showDialog(
      context: context,
      builder:
          (context) => TileInfoModal(
            cellKey: cellKey,
            baseColor: _mapService.getCellColorFromKey(cellKey),
            overlayColor: _pixyService.getOverlayColorFromKey(cellKey),
            registeredBlockData: _blockTracker.getBlockAtCell(cellKey),
            onTrackBlock: _blockTracker.startTrackingBlock,
            cryptoService: _cryptoService,
          ),
    );
  }
}
