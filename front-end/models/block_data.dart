/// Data model representing a detected block with tracking information
/// Contains all necessary metadata for block identification, tracking, and crypto operations
class BlockData {
  final String uuid; // Unique identifier for the block
  final String timestamp; // ISO 8601 timestamp of detection
  final int signature; // Pixy camera signature (1-4 for different colors)
  final String camera; // Source camera identifier
  final int rawX; // Raw X coordinate from camera
  final int rawY; // Raw Y coordinate from camera
  final String cell; // Grid cell coordinate (formatted as "x,y")
  final bool
  startTracking; // Flag to indicate if block should be actively tracked

  /// Constructor for creating a new BlockData instance
  BlockData({
    required this.uuid,
    required this.timestamp,
    required this.signature,
    required this.camera,
    required this.rawX,
    required this.rawY,
    required this.cell,
    this.startTracking = false, // Default to not tracking
  });

  /// Creates a copy of the BlockData with optional overrides
  /// Useful for updating specific fields while maintaining others
  BlockData copyWith({
    String? uuid,
    String? timestamp,
    int? signature,
    String? camera,
    int? rawX,
    int? rawY,
    String? cell,
    bool? startTracking,
  }) {
    return BlockData(
      uuid: uuid ?? this.uuid,
      timestamp: timestamp ?? this.timestamp,
      signature: signature ?? this.signature,
      camera: camera ?? this.camera,
      rawX: rawX ?? this.rawX,
      rawY: rawY ?? this.rawY,
      cell: cell ?? this.cell,
      startTracking: startTracking ?? this.startTracking,
    );
  }

  /// Converts BlockData to JSON format for API communication
  /// Used when sending block data to backend services
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'timestamp': timestamp,
      'signature': signature,
      'camera': camera,
      'raw_x': rawX,
      'raw_y': rawY,
      'cell': cell,
      'start_tracking': startTracking,
    };
  }

  /// Creates BlockData from JSON format
  /// Used when receiving block data from APIs or storage
  factory BlockData.fromJson(Map<String, dynamic> json) {
    return BlockData(
      uuid: json['uuid'],
      timestamp: json['timestamp'],
      signature: json['signature'],
      camera: json['camera'],
      rawX: json['raw_x'],
      rawY: json['raw_y'],
      cell: json['cell'],
      startTracking: json['start_tracking'] ?? false,
    );
  }

  /// Creates BlockData from a Map structure
  /// Alternative constructor for different data formats
  factory BlockData.fromMap(Map<String, dynamic> data) {
    return BlockData(
      uuid: data['uuid'] ?? '',
      timestamp: data['timestamp'] ?? DateTime.now().toIso8601String(),
      signature: data['signature'] ?? 0,
      camera: data['camera'] ?? '',
      rawX: data['raw_x'] ?? 0,
      rawY: data['raw_y'] ?? 0,
      cell: data['cell'] ?? '0,0',
      startTracking: data['start_tracking'] ?? false,
    );
  }
}
