import 'package:flutter/material.dart';
import 'package:brickmmo_pixy_viewer/models/block_data.dart';

/// Informational overlay that appears when hovering over grid cells
/// Provides real-time data about the cell content without requiring clicks
/// Positioned dynamically based on mouse cursor location
class HoverOverlay extends StatelessWidget {
  final BlockData?
  registeredBlockData; // Block data if cell contains a registered block (from capture)
  final String cellKey; // Cell coordinate key in "x,y" format for display
  final Color baseColor; // Base cell color from underlying map data
  final Color? overlayColor; // Current overlay color from Pixy camera detection

  /// Constructor for hover overlay with cell information
  const HoverOverlay({
    super.key,
    required this.cellKey,
    required this.baseColor,
    this.overlayColor,
    this.registeredBlockData,
  });

  @override
  Widget build(BuildContext context) {
    // Build informational content based on cell state
    final children = <Widget>[
      // Basic cell identification
      Text(
        'Cell: $cellKey',
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      Text(
        'Base Color: ${baseColor.value.toRadixString(16).substring(2).toUpperCase()}',
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    ];

    // Add overlay color information if Pixy detection is present
    if (overlayColor != null) {
      children.add(
        Text(
          'Overlay Color: ${overlayColor!.value.toRadixString(16).substring(2).toUpperCase()}',
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      );
    }

    // Add detailed block information if this cell contains a registered block
    if (registeredBlockData != null) {
      final data = registeredBlockData!;
      children.addAll([
        const Divider(color: Colors.white70), // Visual separator
        const Text(
          'Registered Block Data:',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'UUID: ${data.uuid.toString().substring(0, 8)}...', // Truncated UUID
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        Text(
          'Camera: ${data.camera}',
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        Text(
          'Signature: ${data.signature}', // Color signature (1-4)
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        Text(
          'Raw X/Y: (${data.rawX}, ${data.rawY})', // Original camera coordinates
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        Text(
          'Timestamp: ${DateTime.parse(data.timestamp).toLocal().toString().split('.')[0]}',
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      ]);
    } else if (overlayColor != null) {
      // Cell has current Pixy detection but no persistent registration
      children.add(
        const Text(
          'Non-Registered Block (Pixy Data)',
          style: TextStyle(fontSize: 10, color: Colors.white),
        ),
      );
    } else {
      // Cell with only base map data (no blocks detected)
      children.add(
        const Text(
          'Non-Registered Block (Base Data)',
          style: TextStyle(fontSize: 10, color: Colors.white),
        ),
      );
    }

    // Container for the overlay content with semi-transparent background
    return Card(
      color: Colors.black.withOpacity(
        0.7,
      ), // Dark semi-transparent background for readability
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Left-aligned content
          mainAxisSize: MainAxisSize.min, // Only take required space
          children: children,
        ),
      ),
    );
  }
}
