import 'package:flutter/material.dart';
import 'package:brickmmo_pixy_viewer/models/block_data.dart';

/// Visual marker that represents a tracked block on the grid
/// Appears as a colored square with block information and tracking status
/// Can be tapped for interactions and provides visual feedback for block states
class TrackedBlockTooltip extends StatelessWidget {
  final BlockData blockData; // The block data being represented
  final VoidCallback onClose; // Callback to stop tracking this block
  final bool isTracking; // Whether this block is actively being tracked
  final double cellWidth; // Width to match grid cell size for proper alignment

  const TrackedBlockTooltip({
    super.key,
    required this.blockData,
    required this.onClose,
    required this.isTracking,
    required this.cellWidth,
  });

  /// Maps signature numbers to display colors for visual identification
  Color _getSignatureColor(int? signature) {
    switch (signature) {
      case 1:
        return Colors.red.withOpacity(0.8); // Signature 1: Red
      case 2:
        return Colors.orange.withOpacity(0.8); // Signature 2: Orange
      case 3:
        return Colors.blue.withOpacity(0.8); // Signature 3: Blue
      case 4:
        return Colors.green.withOpacity(0.8); // Signature 4: Green
      default:
        return Colors.deepPurple.withOpacity(0.8); // Unknown: Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get background color based on block signature
    final backgroundColor = _getSignatureColor(blockData.signature);

    return Material(
      elevation: 2.0, // Subtle shadow for depth
      borderRadius: BorderRadius.circular(4.0), // Slightly rounded corners
      color: backgroundColor, // Signature-based background color
      child: InkWell(
        // Makes the entire block tappable
        onTap: () {
          // Debug tap handling - could be extended for more interactions
          debugPrint('Tapped Tracked Block: ${blockData.uuid}');
        },
        child: Container(
          width: cellWidth, // Match grid cell size for perfect alignment
          height: cellWidth, // Square aspect ratio
          decoration: BoxDecoration(
            border: Border.all(
              color: isTracking ? Colors.yellowAccent : Colors.white70,
              width: 1.5, // Thicker border for better visibility
            ),
            borderRadius: BorderRadius.circular(
              4.0,
            ), // Match outer borderRadius
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Center content vertically
              children: [
                // Block identification text
                Text(
                  'S:${blockData.signature}, C:${blockData.camera.toString().substring(0, 3)}',
                  style: const TextStyle(
                    color: Colors.white, // White text for contrast
                    fontWeight: FontWeight.bold,
                    fontSize: 8, // Small font to fit in block
                  ),
                  textAlign: TextAlign.center,
                ),

                // Tracking status indicator icon
                if (isTracking)
                  const Icon(
                    Icons.track_changes,
                    color: Colors.lightGreenAccent,
                    size: 12,
                  ),

                // Optional: Uncomment to add close button directly on block
                /*
                IconButton(
                  icon: const Icon(Icons.close, size: 12, color: Colors.white),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                */
              ],
            ),
          ),
        ),
      ),
    );
  }
}
