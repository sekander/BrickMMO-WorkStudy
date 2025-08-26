import 'dart:async';
import 'dart:convert';
import 'package:flutter/animation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:brickmmo_pixy_viewer/models/block_data.dart';
import 'package:flutter/material.dart';

/// Service for tracking block movement and managing block animations
/// Handles block prediction, animation, and backend communication
class BlockTracker {
  /// Registered blocks keyed by cell coordinate
  final Map<String, BlockData> roadBlockUUIDs = {};

  /// Active tracking timers for periodic updates
  final Map<String, Timer> trackingTimers = {};

  /// Currently tracked blocks with full data
  final Map<String, BlockData> _trackedBlocks = {};

  /// Movement history for prediction algorithms
  final Map<String, List<Map<String, dynamic>>> _blockMovementHistory = {};

  /// Predicted positions for smooth animations
  final Map<String, Offset> _predictedBlockPositions = {};

  /// Animation controllers for smooth block movement
  final Map<String, AnimationController> _blockAnimationControllers = {};

  /// Animation objects for block movement
  final Map<String, Animation<Offset>> _blockAnimations = {};

  final Uuid uuid = Uuid(); // UUID generator for new blocks

  /// Ticker provider for animations (set during initialization)
  TickerProvider? _tickerProvider;

  /// Current cell size for position calculations
  double _cellSize = 30.0;

  bool _sendingToBackend = false;
  bool get isSendingToBackend => _sendingToBackend;
  set isSendingToBackend(bool value) {
    _sendingToBackend = value;
    _notifyListeners();
  }

  /// Listeners for state change notifications
  final List<VoidCallback> _listeners = [];

  /// Initializes the tracker with animation capabilities
  void init(TickerProvider tickerProvider) {
    _tickerProvider = tickerProvider;
  }

  /// Updates cell size for proper position calculations
  void setCellSize(double cellSize) {
    _cellSize = cellSize;
  }

  /// Registers captured blocks and logs them
  void registerCapturedBlocks(Map<String, BlockData> capturedBlocks) {
    roadBlockUUIDs.addAll(capturedBlocks);

    _logCapturedBlocks();
    _notifyListeners();
  }

  /// Logs captured block details to console
  void _logCapturedBlocks() {
    for (final entry in roadBlockUUIDs.entries) {
      print(
        'Captured Block:\n'
        '  Cell: ${entry.key}\n'
        '  UUID: ${entry.value.uuid}\n'
        '  Camera: ${entry.value.camera}\n'
        '  Signature: ${entry.value.signature}\n'
        '  Cell X/Y: (${entry.value.cell})\n'
        '  Raw X/Y: (${entry.value.rawX}, ${entry.value.rawY})\n'
        '  Timestamp: ${entry.value.timestamp}\n',
      );
    }
  }

  /// Sends all registered blocks to backend API
  // Future<List<Map<String, dynamic>>> sendBlocksToBackend() async {
  Future<void> sendBlocksToBackend() async {
    const endpoint = 'https://nahid-sekander.duckdns.org/pixy/insert_detection';

    final List<Map<String, dynamic>> successfulBlocks = [];

    for (final block in roadBlockUUIDs.values) {
      await _sendSingleBlock(endpoint, block);
      // final result = await _sendSingleBlock(endpoint, block);
      // if (result != null) {
      //   successfulBlocks.add(result);
      // }
      if (block != null) {
        print(
          "✅ Successfully sent block to be registered with mongo: ${block.uuid}",
        );
      }
    }

    // return successfulBlocks;
  }

  /// Sends individual block to backend with error handling
  // Future<Map<String, dynamic>?> _sendSingleBlock(
  //   String endpoint,
  //   BlockData block,
  // ) async {
  Future<void> _sendSingleBlock(String endpoint, BlockData block) async {
    final payload = {
      'camera': block.camera,
      'signature': block.signature,
      'cell': block.cell,
      'x': block.rawX,
      'y': block.rawY,
      'width': 0,
      'height': 0,
      'detection_id': block.uuid,
    };

    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        // body: json.encode({
        //   'camera': block.camera,
        //   'signature': block.signature,
        //   'cell': block.cell,
        //   'x': block.rawX,
        //   'y': block.rawY,
        //   'width': 0,
        //   'height': 0,
        //   'detection_id': block.uuid,
        // }),
        body: json.encode(payload),
      );

      if (res.statusCode == 201) {
        print("✅ Block sent: ${block.uuid}");
        // return payload;
      } else {
        print("❌ Failed to send block: ${res.body}");
        // return null;
      }
    } catch (e) {
      print("🔥 Error sending block: $e");
      // return null;
    }
  }

  /// Monitors all tracked blocks against current Pixy data
  void monitorAllBlocks(Map<String, Map<String, dynamic>> pixyBlockData) {
    _trackedBlocks.forEach((uuid, blockData) {
      monitorBlockPosition(uuid, blockData, pixyBlockData);
    });
  }

  /// Monitors individual block position and handles movement
  void monitorBlockPosition(
    String uuid,
    BlockData blockData,
    Map<String, Map<String, dynamic>>
    pixyBlockData, // Changed to full block data
  ) {
    final currentCell = blockData.cell;
    final signature = blockData.signature;

    // Predictive logic using movement history
    String? predictedNextCell;
    final history = _blockMovementHistory[uuid];
    if (history != null && history.length >= 2) {
      final lastPos = history[history.length - 1];
      final secondLastPos = history[history.length - 2];
      final dx = lastPos['x'] - secondLastPos['x'];
      final dy = lastPos['y'] - secondLastPos['y'];
      final predictedX = lastPos['x'] + dx;
      final predictedY = lastPos['y'] + dy;
      predictedNextCell = '$predictedX,$predictedY';
    }

    // Check if block is still in its reported position
    final currentCellData = pixyBlockData[currentCell];
    if (currentCellData == null || currentCellData['signature'] != signature) {
      // If not in current cell, check predicted and adjacent cells
      final parts = currentCell.split(',');
      final x = int.parse(parts[0]);
      final y = int.parse(parts[1]);

      final cellsToCheck = <String>{};
      if (predictedNextCell != null) cellsToCheck.add(predictedNextCell);
      cellsToCheck.addAll([
        '${x},${y - 1}', '${x},${y + 1}', // Vertical neighbors
        '${x - 1},${y}', '${x + 1},${y}', // Horizontal neighbors
        currentCell, // Original cell as fallback
      ]);

      for (final cell in cellsToCheck) {
        final cellData = pixyBlockData[cell];
        if (cellData != null && cellData['signature'] == signature) {
          if (cell != currentCell) {
            // Get the exact raw coordinates from Pixy data for the new position
            final newRawX = cellData['x'];
            final newRawY = cellData['y'];
            updateBlockPosition(uuid, cell, newRawX, newRawY);
          }
          return;
        }
      }
    }
  }

  /// Updates block position with exact raw coordinates from Pixy
  void updateBlockPosition(
    String uuid,
    String newCell,
    int newRawX,
    int newRawY,
  ) {
    if (!_trackedBlocks.containsKey(uuid)) return;

    final blockData = _trackedBlocks[uuid]!;
    final previousCell = blockData.cell;

    // Update block data with new position and current raw coordinates
    final updatedBlock = blockData.copyWith(
      cell: newCell,
      rawX: newRawX, // ✅ Update with current raw X from Pixy
      rawY: newRawY, // ✅ Update with current raw Y from Pixy
      timestamp: DateTime.now().toIso8601String(),
    );

    _trackedBlocks[uuid] = updatedBlock;

    // Update road block registry
    if (roadBlockUUIDs.containsKey(previousCell)) {
      roadBlockUUIDs.remove(previousCell);
    }
    roadBlockUUIDs[newCell] = updatedBlock;

    final parts = newCell.split(',');
    final x = int.parse(parts[0]);
    final y = int.parse(parts[1]);

    // Record movement for future prediction
    if (!_blockMovementHistory.containsKey(uuid)) {
      _blockMovementHistory[uuid] = [];
    }
    _blockMovementHistory[uuid]!.add({
      'x': x,
      'y': y,
      'timestamp': DateTime.now(),
    });

    // Keep history manageable
    if (_blockMovementHistory[uuid]!.length > 5) {
      _blockMovementHistory[uuid]!.removeAt(0);
    }

    // Start smooth animation to new position
    _startBlockAnimation(uuid, previousCell, newCell);
    _notifyListeners();
  }

  /*
  /// Monitors all tracked blocks against current Pixy data
  void monitorAllBlocks(Map<String, Color> pixyOverlayColors) {
    _trackedBlocks.forEach((uuid, blockData) {
      monitorBlockPosition(uuid, blockData, pixyOverlayColors);
    });
  }

  /// Monitors individual block position and handles movement
  void monitorBlockPosition(
    String uuid,
    BlockData blockData,
    Map<String, Color> pixyOverlayColors,
  ) {
    final currentCell = blockData.cell;
    final signature = blockData.signature;
    final parts = currentCell.split(',');
    final rawx = blockData.rawX;
    final rawy = blockData.rawY;
    final x = int.parse(parts[0]);
    final y = int.parse(parts[1]);

    // Predictive logic using movement history
    String? predictedNextCell;
    final history = _blockMovementHistory[uuid];
    if (history != null && history.length >= 2) {
      final lastPos = history[history.length - 1];
      final secondLastPos = history[history.length - 2];
      final dx = lastPos['x'] - secondLastPos['x'];
      final dy = lastPos['y'] - secondLastPos['y'];
      final predictedX = lastPos['x'] + dx;
      final predictedY = lastPos['y'] + dy;
      predictedNextCell = '$predictedX,$predictedY';
    }

    // Check if block is still in its reported position
    if (!pixyOverlayColors.containsKey(currentCell) ||
        pixyOverlayColors[currentCell] != _getSignatureColor(signature)) {
      // Check predicted and adjacent cells for the block
      final cellsToCheck = <String>{};
      if (predictedNextCell != null) cellsToCheck.add(predictedNextCell);
      cellsToCheck.addAll([
        '${x},${y - 1}', '${x},${y + 1}', // Vertical neighbors
        '${x - 1},${y}', '${x + 1},${y}', // Horizontal neighbors
        currentCell, // Original cell as fallback
      ]);

      for (final cell in cellsToCheck) {
        if (pixyOverlayColors.containsKey(cell) &&
            pixyOverlayColors[cell] == _getSignatureColor(signature)) {
          if (cell != currentCell) {
            updateBlockPosition(uuid, cell, rawx, rawy);
          }
          return;
        }
      }
    }
  }

  /// Updates block position and triggers animation
  void updateBlockPosition(
    String uuid,
    String newCell,
    int newRawX,
    int newRawY,
  ) {
    if (!_trackedBlocks.containsKey(uuid)) return;

    final blockData = _trackedBlocks[uuid]!;
    final previousCell = blockData.cell;
    final parts = newCell.split(',');
    final x = int.parse(parts[0]);
    final y = int.parse(parts[1]);

    // Update block data with new position and current raw coordinates
    final updatedBlock = blockData.copyWith(
      cell: newCell,
      rawX: newRawX, // ✅ Use the current raw X from camera
      rawY: newRawY, // ✅ Use the current raw Y from camera
      timestamp: DateTime.now().toIso8601String(),
    );

    _trackedBlocks[uuid] = updatedBlock;

    // Update road block registry
    if (roadBlockUUIDs.containsKey(previousCell)) {
      roadBlockUUIDs.remove(previousCell);
    }
    roadBlockUUIDs[newCell] = updatedBlock;

    // Record movement for future prediction
    if (!_blockMovementHistory.containsKey(uuid)) {
      _blockMovementHistory[uuid] = [];
    }
    _blockMovementHistory[uuid]!.add({
      'x': x,
      'y': y,
      'timestamp': DateTime.now(),
    });

    // Keep history manageable
    if (_blockMovementHistory[uuid]!.length > 5) {
      _blockMovementHistory[uuid]!.removeAt(0);
    }

    // Start smooth animation to new position
    _startBlockAnimation(uuid, previousCell, newCell);
    _notifyListeners();
  }
  */

  /// Updates block position and triggers animation
  // void updateBlockPosition(String uuid, String newCell) {
  //   if (!_trackedBlocks.containsKey(uuid)) return;

  //   final blockData = _trackedBlocks[uuid]!;
  //   final previousCell = blockData.cell;
  //   final parts = newCell.split(',');
  //   final x = int.parse(parts[0]);
  //   final y = int.parse(parts[1]);

  //   // Update block data with new position
  //   final updatedBlock = blockData.copyWith(
  //     cell: newCell,
  //     // rawX: x,
  //     // rawY: y,
  //     timestamp: DateTime.now().toIso8601String(),
  //   );

  //   _trackedBlocks[uuid] = updatedBlock;

  //   // Update road block registry
  //   if (roadBlockUUIDs.containsKey(previousCell)) {
  //     roadBlockUUIDs.remove(previousCell);
  //   }
  //   roadBlockUUIDs[newCell] = updatedBlock;

  //   // Record movement for future prediction
  //   if (!_blockMovementHistory.containsKey(uuid)) {
  //     _blockMovementHistory[uuid] = [];
  //   }
  //   _blockMovementHistory[uuid]!.add({
  //     'x': x,
  //     'y': y,
  //     'timestamp': DateTime.now(),
  //   });

  //   // Keep history manageable
  //   if (_blockMovementHistory[uuid]!.length > 5) {
  //     _blockMovementHistory[uuid]!.removeAt(0);
  //   }

  //   // Start smooth animation to new position
  //   _startBlockAnimation(uuid, previousCell, newCell);
  //   _notifyListeners();
  // }

  /// Starts tracking a block with periodic updates
  void startTrackingBlock(BlockData blockData) {
    final uuid = blockData.uuid;
    if (trackingTimers.containsKey(uuid)) return;

    // Ensure block is in registry
    if (roadBlockUUIDs.containsKey(blockData.cell)) {
      roadBlockUUIDs[blockData.cell] = blockData;
    }

    // Add to tracked blocks if not already there
    if (!_trackedBlocks.containsKey(uuid)) {
      _addTrackedBlock(blockData);
    }

    // Initialize movement history
    _blockMovementHistory[uuid] = [
      {'x': blockData.rawX, 'y': blockData.rawY, 'timestamp': DateTime.now()},
    ];

    // Start periodic tracking updates
    trackingTimers[uuid] = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_trackedBlocks.containsKey(uuid)) {
        timer.cancel();
        trackingTimers.remove(uuid);
        return;
      }

      // Only send tracking update if user sends to backend
      // (No automatic tracking update here)
      if (_sendingToBackend) {
        _sendTrackingUpdate(uuid);
      }
      // _sendTrackingUpdate(uuid);
    });

    _notifyListeners();
  }

  /// Sends tracking update to backend API
  Future<void> _sendTrackingUpdate(String uuid) async {
    try {
      final block = _trackedBlocks[uuid]!;
      final response = await http.post(
        Uri.parse('https://nahid-sekander.duckdns.org/pixy/update_tracking'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'detection_id': uuid,
          'x': block.rawX,
          'y': block.rawY,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Tracking update sent for $uuid");

        // PRINT WHAT'S BEING SENT
        print('📤 Sending to backend:');
        // print('URL: $endpoint');
        // print('Payload: ${json.encode(payload)}');
        print('Full block data:');
        print('  UUID: ${block.uuid}');
        print('  Camera: ${block.camera}');
        print('  Signature: ${block.signature}');
        print('  rawX: ${block.rawX}');
        print('  rawY: ${block.rawY}');
        print('  Cell: ${block.cell}');
        print('  Timestamp: ${block.timestamp}');
        print('─' * 50);
      } else {
        print("❌ Tracking update failed for $uuid");
      }
    } catch (e) {
      print("🔥 Tracking error: $e");
    }
  }

  /// Adds a block to tracked collection and starts animation
  void _addTrackedBlock(BlockData blockData) {
    final uuid = blockData.uuid;
    if (!_trackedBlocks.containsKey(uuid)) {
      _trackedBlocks[uuid] = blockData;
      _startBlockAnimation(uuid, null, blockData.cell);
    }
  }

  /// Starts smooth animation for block movement
  void _startBlockAnimation(String uuid, String? fromCell, String toCell) {
    final blockData = _trackedBlocks[uuid];
    if (blockData == null || _tickerProvider == null) return;

    // Calculate end position in pixels
    final toParts = toCell.split(',').map(int.parse).toList();
    final Offset endOffset = Offset(
      toParts[0] * _cellSize,
      toParts[1] * _cellSize,
    );

    // Calculate start position
    Offset startOffset;
    if (fromCell == null || fromCell == toCell) {
      startOffset = endOffset;
    } else {
      final fromParts = fromCell.split(',').map(int.parse).toList();
      startOffset = Offset(fromParts[0] * _cellSize, fromParts[1] * _cellSize);
    }

    // Create or reuse animation controller
    AnimationController controller =
        _blockAnimationControllers[uuid] ??
        AnimationController(
          vsync: _tickerProvider!,
          duration: const Duration(milliseconds: 300),
        );
    _blockAnimationControllers[uuid] = controller;

    // Setup animation
    _blockAnimations[uuid] =
        Tween<Offset>(begin: startOffset, end: endOffset).animate(controller)
          ..addListener(() {
            _predictedBlockPositions[uuid] = _blockAnimations[uuid]!.value;
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _predictedBlockPositions.remove(uuid);
            }
          });

    // Start animation
    controller.reset();
    controller.forward();
  }

  /// Stops tracking a block and cleans up resources
  void stopTrackingBlock(String uuid) {
    _sendingToBackend = false;
    trackingTimers[uuid]?.cancel();
    trackingTimers.remove(uuid);
    _removeTrackedBlock(uuid);
    _notifyListeners();
  }

  /// Removes a block from tracking and cleans up
  void _removeTrackedBlock(String uuid) {
    if (_trackedBlocks.containsKey(uuid)) {
      _trackedBlocks.remove(uuid);
    }
    _blockAnimationControllers[uuid]?.dispose();
    _blockAnimationControllers.remove(uuid);
    _blockAnimations.remove(uuid);
    _predictedBlockPositions.remove(uuid);
    _blockMovementHistory.remove(uuid);
  }

  /// Cleanup method to release all resources
  void dispose() {
    trackingTimers.values.forEach((timer) => timer.cancel());
    trackingTimers.clear();
    _blockAnimationControllers.values.forEach(
      (controller) => controller.dispose(),
    );
    _blockAnimationControllers.clear();
  }

  /// Gets block at specific cell coordinate
  BlockData? getBlockAtCell(String cellKey) => roadBlockUUIDs[cellKey];

  /// Maps signature to color for display
  Color _getSignatureColor(int signature) {
    return const {
          1: Colors.red,
          2: Colors.orange,
          3: Colors.blue,
          4: Colors.green,
        }[signature] ??
        Colors.grey;
  }

  /// Listener management for state changes
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Public access to tracked data
  Map<String, BlockData> get trackedBlocks => _trackedBlocks;
  Map<String, Offset> get predictedBlockPositions => _predictedBlockPositions;
}
