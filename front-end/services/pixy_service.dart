import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:brickmmo_pixy_viewer/models/block_data.dart';
import 'package:brickmmo_pixy_viewer/services/map_service.dart';

/// Service for handling Pixy camera data and block detection
/// Manages communication with Pixy camera endpoints
/// Processes block detection data and handles block registration
class PixyService {
  final MapService
  mapService; // Reference to map service for cell color checking
  final Uuid _uuid = Uuid(); // UUID generator for block identification

  /// Current overlay colors from Pixy camera detection
  Map<String, Color> pixyOverlayColors = {};

  /// Previous overlay colors for change detection
  Map<String, Color> previousPixyOverlayColors = {};

  // Full block data from Pixy camera detection (keyed by cell coordinate)
  Map<String, Map<String, dynamic>> pixyBlockData = {};

  Map<String, Color> cellColors = {};

  /// Disabled signatures (1-4) that should be ignored
  Set<int> disabledSignatures = {};

  /// Disabled camera sources that should be ignored
  Set<String> disabledCameras = {};

  /// Route toggle states for API endpoint selection
  bool toggleRoute0 = false;
  bool toggleRoute1 = false;

  /// Filter settings for block display
  bool showBlocksOnRoad = true;
  bool showBlocksOnTrack = true;
  bool showBlocksOnPlain = true;

  Completer<void>? _overlayLoopCompleter; // Controls the overlay update loop

  /// Constructor with dependency injection of MapService
  PixyService(this.mapService);

  /// Fetches and processes Pixy overlay data from all active endpoints
  /// Updates the overlay colors based on detected blocks
  Future<void> fetchPixyOverlay() async {
    // Build list of active endpoints based on route toggles
    final urls = [
      if (!toggleRoute0) 'https://nahid-sekander.duckdns.org/pixy/get_json_0',
      if (!toggleRoute1) 'https://nahid-sekander.duckdns.org/pixy/get_json_1',
    ];

    // Fetch blocks from all active endpoints
    final allBlocks = await _fetchAllBlocks(urls);

    // Store previous state for change detection
    previousPixyOverlayColors = Map<String, Color>.from(pixyOverlayColors);
    pixyOverlayColors.clear();
    pixyBlockData.clear();

    // Process each detected block and update overlay
    for (final block in allBlocks) {
      final sig = block['signature'];
      if (sig == null || disabledSignatures.contains(sig)) continue;

      // Convert camera coordinates to grid coordinates (20px per cell)
      final cellX = (block['x'] / 20).floor();
      final cellY = (block['y'] / 20).floor();
      final key = '$cellX,$cellY';
      final tile = mapService.getCellColorFromKey(key);

      // Add to overlay if it should be shown based on filters
      // final color = _getSignatureColor(sig);
      // pixyOverlayColors[key] = color;

      if (_shouldShowBlock(tile)) {
        final color = _getSignatureColor(sig);
        pixyOverlayColors[key] = color;
        pixyBlockData[key] = block; // Store full block data
        // The check for movement is now handled inside _monitorBlockPosition
        // This ensures that actual tracked blocks use the predictive logic.
      }
    }
  }

  /// Fetches blocks from multiple URLs with error handling
  Future<List<dynamic>> _fetchAllBlocks(List<String> urls) async {
    final allBlocks = <dynamic>[];
    for (final url in urls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          allBlocks.addAll(_processPixyData(json.decode(response.body)));
        }
      } catch (e) {
        // print('Error fetching data from $url: $e');
      }
    }
    return allBlocks;
  }

  bool _shouldShowBlock(Color? tile) {
    return (tile == Colors.greenAccent && showBlocksOnRoad) ||
        (tile == Colors.lightBlueAccent && showBlocksOnTrack) ||
        (tile == Colors.grey.shade300 && showBlocksOnPlain);
  }

  /// Processes raw Pixy JSON data and filters based on settings
  List<dynamic> _processPixyData(dynamic jsonData) {
    final blocks = <dynamic>[];
    for (final entry in (jsonData as List)) {
      final camera = entry['camera'] as String? ?? '';
      if (disabledCameras.contains(camera)) continue;

      if (entry['blocks'] != null) {
        // Filter out disabled signatures
        blocks.addAll(
          (entry['blocks'] as List).where(
            (b) => !disabledSignatures.contains(b['signature']),
          ),
        );
      }
    }
    return blocks;
  }

  /// Maps signature numbers to display colors
  Color _getSignatureColor(dynamic sig) {
    return const {
          1: Colors.red, // Signature 1 -> Red
          2: Colors.orange, // Signature 2 -> Orange
          3: Colors.blue, // Signature 3 -> Blue
          4: Colors.green, // Signature 4 -> Green
        }[sig] ??
        Colors.grey; // Unknown signature -> Grey
  }

  /// Captures blocks for a specified duration
  /// Used for block registration with unique IDs
  Future<Map<String, BlockData>> captureBlocksForDuration(
    Duration duration,
  ) async {
    final captured = <String, BlockData>{};
    final startTime = DateTime.now();

    // Capture blocks continuously for the specified duration
    while (DateTime.now().difference(startTime) < duration) {
      await _captureBlocksFromUrls([
        'https://nahid-sekander.duckdns.org/pixy/get_json_0',
        'https://nahid-sekander.duckdns.org/pixy/get_json_1',
      ], captured);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    return captured;
  }

  /// Captures blocks from multiple URLs
  Future<void> _captureBlocksFromUrls(
    List<String> urls,
    Map<String, BlockData> captured,
  ) async {
    for (final url in urls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          _processCaptureResponse(json.decode(response.body), captured);
        }
      } catch (e) {
        print('Capture error: $e');
      }
    }
  }

  /// Processes capture response and extracts valid blocks
  void _processCaptureResponse(
    dynamic jsonData,
    Map<String, BlockData> captured,
  ) {
    for (final entry in (jsonData as List)) {
      final camera = entry['camera'] as String? ?? '';
      if (disabledCameras.contains(camera)) continue;

      if (entry['blocks'] != null) {
        for (final block in entry['blocks']) {
          _processSingleBlock(block, captured, camera);
        }
      }
    }
  }

  /// Processes individual block and adds to captured collection if valid
  void _processSingleBlock(
    Map<String, dynamic> block,
    Map<String, BlockData> captured,
    String camera,
  ) {
    final sig = block['signature'];
    if (sig == null || disabledSignatures.contains(sig)) return;

    // Convert to grid coordinates
    final x = (block['x'] / 20).floor();
    final y = (block['y'] / 20).floor();
    final key = '$x,$y';

    // Only capture blocks on roads (green cells) that aren't already captured
    final cellColor = mapService.getCellColorFromKey(key);
    if (cellColor == Colors.greenAccent && !captured.containsKey(key)) {
      captured[key] = _createBlockData(
        block['x'],
        block['y'],
        x,
        y,
        sig,
        camera,
      );
    }
  }

  /// Creates BlockData with unique ID and timestamp
  BlockData _createBlockData(
    int rawx,
    int rawy,
    int x,
    int y,
    int sig,
    String camera,
  ) {
    return BlockData(
      uuid: _uuid.v4(), // Generate unique identifier
      timestamp: DateTime.now().toIso8601String(),
      signature: sig,
      camera: camera,
      rawX: rawx,
      rawY: rawy,
      cell: '$x,$y',
    );
  }

  /// Starts the continuous overlay update loop
  void startOverlayLoop({
    required bool Function() isActive,
    required VoidCallback onUpdate,
  }) {
    _overlayLoopCompleter = Completer<void>();
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!isActive() || _overlayLoopCompleter!.isCompleted) return false;
      await fetchPixyOverlay();
      onUpdate();
      return true;
    });
  }

  /// Cleanup method to stop the overlay loop
  void dispose() {
    _overlayLoopCompleter?.complete();
  }

  /// Helper methods for color access
  Color? getOverlayColor(int x, int y) => pixyOverlayColors['$x,$y'];
  Color? getOverlayColorFromKey(String key) => pixyOverlayColors[key];

  /// Route toggle setters
  void setToggleRoute0(bool value) => toggleRoute0 = value;
  void setToggleRoute1(bool value) => toggleRoute1 = value;

  // Add this getter method to access the full block data
  Map<String, Map<String, dynamic>> get currentPixyBlockData => pixyBlockData;
}
