import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service responsible for loading and managing map grid data
/// Handles API communication with brickmmo.com map endpoints
/// Manages grid cell colors and camera tint effects
class MapService {
  /// Cache of cell colors keyed by coordinate string "x,y"
  Map<String, Color> cellColors = {};

  /// Grid dimensions - updated based on loaded map data
  int maxX = 30, maxY = 30;

  /// Camera tint toggle states
  bool cameraOneTint = false;
  bool cameraTwoTint = false;

  /// Fetches map grid data from the brickmmo.com API
  /// Processes the response and updates internal state
  Future<void> loadMapData() async {
    try {
      print('Loading map data from API...');
      final response = await http.get(
        Uri.parse('https://api.brickmmo.com/map/grid/city_id/1'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _processMapData(data);
        print('Map data loaded successfully. Grid size: $maxX x $maxY');
      } else {
        print('Failed to load map data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading grid: $e');
    }
  }

  /// Processes raw map data from API response
  /// Extracts grid information and determines cell colors
  void _processMapData(Map<String, dynamic> data) {
    final squares = data['squares'] as List;
    int maxXFound = 0, maxYFound = 0;
    final newCellColors = <String, Color>{};

    // Process each grid square to determine cell type and color
    for (final sq in squares) {
      final x = int.parse(sq['x']);
      final y = int.parse(sq['y']);
      maxXFound = x > maxXFound ? x : maxXFound;
      maxYFound = y > maxYFound ? y : maxYFound;

      final key = '$x,$y';
      newCellColors[key] = _determineCellColor(sq);
    }

    // Apply camera tint effects if enabled
    _applyCameraTints(newCellColors);

    // Update grid dimensions (add 1 because coordinates are 0-based)
    maxX = maxXFound + 1;
    maxY = maxYFound + 1;
    cellColors = newCellColors;
  }

  /// Determines cell color based on square properties
  /// Roads -> Green, Tracks -> Light Blue, Default -> Grey
  Color _determineCellColor(Map<String, dynamic> square) {
    if (int.parse(square['tracks']) > 0) return Colors.lightBlueAccent;
    if (int.parse(square['roads']) > 0) return Colors.greenAccent;
    return Colors.grey.shade300;
  }

  /// Applies camera tint effects to specified grid regions
  /// Modifies colors in the specified rectangular area
  void _applyCameraTints(Map<String, Color> colors) {
    if (cameraOneTint) _applyTint(colors, 0, 15, 0, 11, [25, 10, 5]);
    if (cameraTwoTint) _applyTint(colors, 15, 30, 0, 11, [5, 15, 30]);
  }

  /// Applies RGB adjustments to colors in a specific grid region
  /// Used for visual differentiation of camera coverage areas
  void _applyTint(
    Map<String, Color> colors,
    int xStart,
    int xEnd,
    int yStart,
    int yEnd,
    List<int> rgbAdjustments,
  ) {
    for (int x = xStart; x < xEnd; x++) {
      for (int y = yStart; y < yEnd; y++) {
        final key = '$x,$y';
        if (colors.containsKey(key)) {
          colors[key] = _adjustColor(colors[key]!, rgbAdjustments);
        }
      }
    }
  }

  /// Adjusts individual color channels with clamping to valid ranges
  Color _adjustColor(Color base, List<int> adjustments) {
    return Color.fromARGB(
      base.alpha,
      (base.red + adjustments[0]).clamp(0, 255),
      (base.green + adjustments[1]).clamp(0, 255),
      (base.blue + adjustments[2]).clamp(0, 255),
    ).withOpacity(0.8);
  }

  /// Gets cell color by coordinates - returns null if cell doesn't exist
  Color? getCellColor(int x, int y) => cellColors['$x,$y'];

  /// Gets cell color by coordinate key with fallback to default color
  Color getCellColorFromKey(String key) =>
      cellColors[key] ?? Colors.grey.shade300;

  /// Toggles camera 1 tint effect
  void toggleCameraOneTint() => cameraOneTint = !cameraOneTint;

  /// Toggles camera 2 tint effect
  void toggleCameraTwoTint() => cameraTwoTint = !cameraTwoTint;
}
