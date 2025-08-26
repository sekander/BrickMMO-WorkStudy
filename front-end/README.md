# BrickMMO Pixy Viewer - Frontend

A Flutter-based frontend application for visualizing and tracking LEGO blocks detected by Pixy cameras in the BrickMMO ecosystem.  
This application provides real-time monitoring, block registration, tracking, and integration with cryptocurrency operations.

---

## 🚀 Features

- **Real-time Block Visualization**: Live overlay of detected blocks on city grid  
- **Block Registration & Tracking**: Capture and monitor individual blocks with unique UUIDs  
- **Predictive Movement**: AI-powered movement prediction for smooth block tracking  
- **Multi-Camera Support**: Support for multiple Pixy camera endpoints  
- **Cryptocurrency Integration**: Built-in crypto wallet operations and transactions  
- **Responsive UI**: Adaptive design that works on desktop, tablet, and mobile  
- **Interactive Grid**: Hover and click interactions with detailed block information  

---

## 🛠️ Tech Stack

- **Framework**: Flutter 3.0+  
- **Language**: Dart  
- **State Management**: Built-in listeners and callbacks  
- **HTTP Client**: `http` package for API communication  
- **UUID Generation**: `uuid` package for unique identifiers  
- **Shared Preferences**: For local storage of user sessions  

---

## 📦 Project Structure

```text
lib/
├── main.dart                   # Application entry point
├── models/
│   └── block_data.dart          # Block data model and serialization
├── services/
│   ├── block_tracker.dart       # Block tracking and movement prediction
│   ├── crypto_service.dart      # Cryptocurrency operations
│   ├── map_service.dart         # Grid map data handling
│   └── pixy_service.dart        # Pixy camera communication
├── views/
│   ├── city_grid_view.dart      # Main grid visualization
│   ├── original_camera_view.dart
│   ├── pixy_blocks_view.dart
│   └── undistorted_camera_view.dart
└── widgets/
    ├── grid_cell.dart           # Individual grid cell component
    ├── home_switcher.dart       # Navigation controller
    ├── hover_overlay.dart       # Information overlay
    ├── initial_loader.dart      # Splash screen and initialization
    ├── splash_screen.dart       # Animated splash screen
    ├── tile_info_modal.dart     # Detailed block information modal
    ├── tracked_blocks_panel.dart # Tracking control panel
    └── tracked_block_tooltip.dart # Visual block markers
````

---

## 🏗️ Architecture

The application follows a **service-based architecture**:

1. **Services Layer**: Handles all business logic and API communications
2. **Models Layer**: Data structures and serialization/deserialization
3. **Views Layer**: Main screen components and navigation
4. **Widgets Layer**: Reusable UI components and overlays

---

## 🔧 Installation

### Prerequisites

* Flutter SDK 3.0 or higher
* Dart 2.17 or higher
* Android Studio / VSCode with Flutter extension
* Physical device or emulator

### Setup Steps

1. **Clone the repository**

   ```bash
   git clone <your-repo-url>
   cd brickmmo_pixy_viewer
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the application**

   ```bash
   flutter run
   ```

4. **Build for production**

   ```bash
   flutter build apk   # For Android
   flutter build ios   # For iOS
   flutter build web   # For web
   ```

---

## ⚙️ Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
PIXY_API_BASE_URL=https://nahid-sekander.duckdns.org
CRYPTO_API_BASE_URL=http://192.168/projects/crypto/api
```

### API Endpoints

* `GET /pixy/get_json_0` → Pixy camera 1 data
* `GET /pixy/get_json_1` → Pixy camera 2 data
* `POST /pixy/insert_detection` → Register new blocks
* `POST /pixy/update_tracking` → Update block positions
* `POST /crypto/api/*` → Cryptocurrency operations

---

## 🎮 Usage

### Block Operations

1. **Capture Blocks**: Register new blocks
2. **Track Blocks**: Start tracking for movement monitoring
3. **View Details**: Click on any grid cell for detailed information
4. **Crypto Operations**: Register blocks as crypto users & perform transactions

### Camera Controls

* Toggle between camera feeds
* Enable/disable specific signatures (colours)
* Filter blocks by road/track/plain surfaces

---

## 🔌 API Integration

### Block Data Format

```dart
{
  "uuid": "string",
  "timestamp": "ISO8601",
  "signature": 1-4,
  "camera": "string",
  "raw_x": number,
  "raw_y": number,
  "cell": "x,y",
  "start_tracking": boolean
}
```

### Cryptocurrency Operations

* User registration with wallet creation
* PIN-based authentication
* Coin transfers between addresses
* Balance checking and blockchain loading

---

## 🧪 Testing

Run the full suite:

```bash
flutter test
```

Run specific test files:

```bash
flutter test test/block_tracker_test.dart
flutter test test/pixy_service_test.dart
```

---

## 📊 Performance

* **60 FPS Animation**: Smooth block movement
* **Efficient Rendering**: Optimized grid rendering with reusable widgets
* **Memory Management**: Proper disposal of controllers and listeners
* **Network Optimization**: Efficient API calls with error handling

---

## 🐛 Troubleshooting

### Common Issues

1. **Camera feed not loading** → Check API endpoint connectivity
2. **Blocks not appearing** → Verify signature filters & camera settings
3. **Crypto operations failing** → Ensure backend services are running

### Debug Mode

Enable debug logging:

```dart
void main() {
  debugPrint = (String? message, {int? wrapWidth}) {
    // Custom debug output
  };
  runApp(const BrickMMOApp());
}
```

---
