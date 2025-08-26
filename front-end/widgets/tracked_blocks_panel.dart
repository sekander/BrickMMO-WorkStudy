import 'package:flutter/material.dart';
import 'package:brickmmo_pixy_viewer/models/block_data.dart';
import 'package:brickmmo_pixy_viewer/services/block_tracker.dart';

/// Persistent overlay panel that displays real-time information about tracked blocks
/// Docks in the top-left corner and shows block statistics, movement status, and controls
class TrackedBlocksPanel extends StatefulWidget {
  final BlockTracker blockTracker; // Reference to block tracker service
  final VoidCallback onClose; // Callback to close the panel

  const TrackedBlocksPanel({
    super.key,
    required this.blockTracker,
    required this.onClose,
  });

  @override
  State<TrackedBlocksPanel> createState() => _TrackedBlocksPanelState();
}

class _TrackedBlocksPanelState extends State<TrackedBlocksPanel> {
  @override
  void initState() {
    super.initState();
    // Listen to block tracker changes to automatically update the panel
    widget.blockTracker.addListener(_updatePanel);
  }

  @override
  void dispose() {
    // Remove listener to prevent memory leaks
    widget.blockTracker.removeListener(_updatePanel);
    super.dispose();
  }

  /// Callback method that triggers UI update when block tracker state changes
  void _updatePanel() {
    if (mounted) {
      setState(() {
        // Empty setState call forces rebuild with latest data
      });
    }
  }

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
        return Colors.deepPurple.withOpacity(0.8); // Unknown signature: Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current list of tracked blocks for display
    final trackedBlocks = widget.blockTracker.trackedBlocks.values.toList();

    return Material(
      elevation: 8.0, // Shadow depth for visual hierarchy
      borderRadius: BorderRadius.circular(
        8.0,
      ), // Rounded corners for modern look
      child: Container(
        width: 300, // Fixed width for consistent layout
        padding: const EdgeInsets.all(12.0), // Internal spacing
        decoration: BoxDecoration(
          color: Colors.white, // Clean white background
          borderRadius: BorderRadius.circular(8.0), // Match outer borderRadius
          border: Border.all(color: Colors.grey.shade300), // Subtle border
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Left-aligned content
          mainAxisSize: MainAxisSize.min, // Only take required vertical space
          children: [
            _buildHeader(), // Panel title and close button
            const SizedBox(height: 8), // Spacing between sections
            _buildStats(
              trackedBlocks,
            ), // Statistics row (total, moving, active)
            const SizedBox(height: 12), // Section separator
            Expanded(child: _buildBlocksList(trackedBlocks)),
          ],
        ),
      ),
    );
  }

  /// Builds the header section with title and close button
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween, // Title left, button right
      children: [
        const Text(
          'Tracked Blocks', // Panel title
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue, // Brand color for title
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 20), // Compact close icon
          onPressed: widget.onClose, // Use provided close callback
          tooltip: 'Close panel', // Accessibility tooltip
        ),
      ],
    );
  }

  /// Builds statistics row showing total, moving, and active block counts
  Widget _buildStats(List<BlockData> trackedBlocks) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceAround, // Evenly space statistics
      children: [
        _buildStatItem('Total', trackedBlocks.length.toString(), Colors.blue),
        _buildStatItem(
          'Moving',
          trackedBlocks
              .where(
                (b) => widget.blockTracker.predictedBlockPositions.containsKey(
                  b.uuid,
                ),
              )
              .length
              .toString(),
          Colors.orange, // Orange for moving blocks (attention needed)
        ),
        _buildStatItem(
          'Active',
          trackedBlocks.length
              .toString(), // Placeholder - could implement active logic
          Colors.green, // Green for active blocks (good status)
        ),
      ],
    );
  }

  /// Builds individual statistic item with value and label
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value, // Numeric value (count)
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color, // Color-coded for quick recognition
          ),
        ),
        Text(
          label, // Description label
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey, // Subtle label color
          ),
        ),
      ],
    );
  }

  /// Builds the scrollable list of tracked blocks
  Widget _buildBlocksList(List<BlockData> trackedBlocks) {
    if (trackedBlocks.isEmpty) {
      return const Center(
        child: Text(
          'No blocks being tracked', // Empty state message
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 200,
      ), // Limit height for scroll
      child: ListView.builder(
        shrinkWrap: true, // Only take required space
        itemCount: trackedBlocks.length, // Number of blocks to display
        itemBuilder: (context, index) {
          final block = trackedBlocks[index];
          // Check if block is currently moving (has predicted position)
          final isMoving = widget.blockTracker.predictedBlockPositions
              .containsKey(block.uuid);

          return _buildBlockItem(
            block,
            isMoving,
          ); // Build individual block item
        },
      ),
    );
  }

  /// Builds individual block item with all relevant information and controls
  Widget _buildBlockItem(BlockData block, bool isMoving) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6), // Spacing between block items
      padding: const EdgeInsets.all(8), // Internal padding
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Light background for contrast
        borderRadius: BorderRadius.circular(6), // Rounded corners
        border: Border.all(color: Colors.grey.shade300), // Subtle border
      ),
      child: Row(
        children: [
          // Color indicator circle showing block signature color
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getSignatureColor(
                block.signature,
              ), // Signature-based color
              shape: BoxShape.circle, // Circular indicator
              border: Border.all(
                color: Colors.white,
                width: 2,
              ), // White border for contrast
            ),
          ),
          const SizedBox(width: 8), // Spacing after color indicator
          // Block information section (takes remaining space)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Left-aligned text
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      // UUID part - Red
                      TextSpan(
                        text:
                            '${block.uuid.substring(0, 8)}... ', // First 8 chars of UUID
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Signature part - Color based on signature
                      TextSpan(
                        text: 'S${block.signature} ',
                        style: TextStyle(
                          color: _getSignatureColor(block.signature),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // "@" symbol - Grey
                      const TextSpan(
                        text: '@ ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      // Cell location - Green
                      TextSpan(
                        text: block.cell,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Cam: ${_formatCameraName(block.camera)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: _getSignatureColor(block.signature).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Movement status indicator icon
          Icon(
            isMoving
                ? Icons.directions_run
                : Icons.pause, // Running man for moving, pause for stationary
            size: 16,
            color:
                isMoving
                    ? Colors.green
                    : Colors.grey, // Green for moving, grey for stationary
          ),

          // Stop tracking button
          IconButton(
            icon: const Icon(Icons.stop, size: 16), // Stop icon
            onPressed:
                () => widget.blockTracker.stopTrackingBlock(
                  block.uuid,
                ), // Stop tracking this block
            tooltip: 'Stop tracking', // Accessibility tooltip
          ),
        ],
      ),
    );
  }

  /// Formats camera name for better display (removes redundant text)
  String _formatCameraName(String camera) {
    return camera
        .replaceAll('PI-CAMERA', 'Cam') // Shorten PI-CAMERA to Cam
        .replaceAll('PC-CAMERA', 'PC'); // Shorten PC-CAMERA to PC
  }
}
