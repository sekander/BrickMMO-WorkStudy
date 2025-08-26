import 'package:flutter/material.dart';

/// Individual grid cell widget that represents a single cell in the city grid
/// Handles hover interactions, tapping, and visual representation of map cells
/// This is the fundamental building block of the entire grid visualization system
class GridCell extends StatelessWidget {
  final int x; // X coordinate in the grid (0-based index)
  final int y; // Y coordinate in the grid (0-based index)
  final double cellSize; // Size of the cell in pixels (configurable via UI)
  final Color?
  baseColor; // Base color from map data (roads, tracks, plain areas)
  final Color? overlayColor; // Overlay color from Pixy detection (block colors)
  final bool isHovered; // Whether this cell is currently hovered by mouse
  final Function(Offset)
  onHover; // Callback when cell is hovered (provides position for overlay)
  final VoidCallback
  onHoverExit; // Callback when hover exits cell (hides overlay)
  final VoidCallback
  onTap; // Callback when cell is tapped (shows detailed modal)

  /// Constructor for creating a GridCell with all required properties
  const GridCell({
    super.key,
    required this.x,
    required this.y,
    required this.cellSize,
    required this.baseColor,
    required this.overlayColor,
    required this.isHovered,
    required this.onHover,
    required this.onHoverExit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // Handle hover events with precise position information for overlay placement
      onHover: (event) => onHover(event.position),
      // Handle hover exit to cleanup overlays and state
      onExit: (_) => onHoverExit(),
      child: GestureDetector(
        // Handle tap events to show detailed cell information modal
        onTap: onTap,
        child: Container(
          width: cellSize, // Dynamic width based on user zoom preference
          height: cellSize, // Dynamic height (maintains square aspect ratio)
          margin: const EdgeInsets.all(
            0.5,
          ), // Small margin for grid line visualization
          decoration: BoxDecoration(
            // Priority: overlay color (blocks) > base color (map) > default grey
            color: overlayColor ?? baseColor ?? Colors.grey.shade200,
            // Highlight border when hovered for better user feedback
            border:
                isHovered
                    ? Border.all(color: Colors.yellowAccent, width: 2.0)
                    : null,
          ),
        ),
      ),
    );
  }
}
