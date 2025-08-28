# BrickMMO Pixy Viewer - Frontend

A Flutter-based frontend application for visualizing and tracking LEGO blocks detected by Pixy cameras in the BrickMMO ecosystem. This application provides real-time monitoring, block registration, tracking, and integration with cryptocurrency operations.

## 🚀 Features

- \*\*Real-time Block Visualization\*\*: Live overlay of detected blocks on city grid

- \*\*Block Registration & Tracking\*\*: Capture and monitor individual blocks with unique UUIDs

- \*\*Predictive Movement\*\*: AI-powered movement prediction for smooth block tracking

- \*\*Multi-Camera Support\*\*: Support for multiple Pixy camera endpoints

- \*\*Cryptocurrency Integration\*\*: Built-in crypto wallet operations and transactions

- \*\*Responsive UI\*\*: Adaptive design that works on desktop, tablet, and mobile

- \*\*Interactive Grid\*\*: Hover and click interactions with detailed block information

## 🛠️ Tech Stack

- \*\*Framework\*\*: Flutter 3.0+

- \*\*Language\*\*: Dart

- \*\*State Management\*\*: Built-in listeners and callbacks

- \*\*HTTP Client\*\*: \`http\` package for API communication

- \*\*UUID Generation\*\*: \`uuid\` package for unique identifiers

- \*\*Shared Preferences\*\*: For local storage of user sessions

## 📦 Project Structure

`\`\`

lib/

├── main.dart # Application entry point

├── models/

│ └── block\_data.dart # Block data model and serialization

├── services/

│ ├── block\_tracker.dart # Block tracking and movement prediction

│ ├── crypto\_service.dart # Cryptocurrency operations

│ ├── map\_service.dart # Grid map data handling

│ └── pixy\_service.dart # Pixy camera communication

├── views/

│ ├── city\_grid\_view.dart # Main grid visualization

│ ├── original\_camera\_view.dart

│ ├── pixy\_blocks\_view.dart

│ └── undistorted\_camera\_view.dart

└── widgets/

├── grid\_cell.dart # Individual grid cell component

├── home\_switcher.dart # Navigation controller

├── hover\_overlay.dart # Information overlay

├── initial\_loader.dart # Splash screen and initialization

├── splash\_screen.dart # Animated splash screen

├── tile\_info\_modal.dart # Detailed block information modal

├── tracked\_blocks\_panel.dart # Tracking control panel

└── tracked\_block\_tooltip.dart # Visual block markers

\`\`\`

## 🏗️ Architecture

The application follows a service-based architecture:

1\. \*\*Services Layer\*\*: Handles all business logic and API communications

2\. \*\*Models Layer\*\*: Data structures and serialization/deserialization

3\. \*\*Views Layer\*\*: Main screen components and navigation

4\. \*\*Widgets Layer\*\*: Reusable UI components and overlays

\## 🔧 Installation

\### Prerequisites

\- Flutter SDK 3.0 or higher

\- Dart 2.17 or higher

\- Android Studio/VSCode with Flutter extension

\- Physical device or emulator

\### Setup Steps

1\. \*\*Clone the repository\*\*

\`\`\`bash

git clone

cd brickmmo\_pixy\_viewer

\`\`\`

2\. \*\*Install dependencies\*\*

\`\`\`bash

flutter pub get

\`\`\`

3\. \*\*Run the application\*\*

\`\`\`bash

flutter run

\`\`\`

4\. \*\*Build for production\*\*

\`\`\`bash

flutter build apk # For Android

flutter build ios # For iOS

flutter build web # For web

\`\`\`

## ⚙️ Configuration

### Environment Variables

Create a \`.env\` file in the root directory:

\`\`\`env

PIXY\_API\_BASE\_URL=https://nahid-sekander.duckdns.org

CRYPTO\_API\_BASE\_URL=http://192.168/projects/crypto/api

\`\`\`

### API Endpoints

The application communicates with these endpoints:

\- \`GET /pixy/get\_json\_0\` - Pixy camera 1 data

\- \`GET /pixy/get\_json\_1\` - Pixy camera 2 data

\- \`POST /pixy/insert\_detection\` - Register new blocks

\- \`POST /pixy/update\_tracking\` - Update block positions

\- \`POST /crypto/api/\*\` - Cryptocurrency operations

## 🎮 Usage

### Block Operations

1\. \*\*Capture Blocks\*\*: Use the capture functionality to register new blocks

2\. \*\*Track Blocks\*\*: Start tracking individual blocks for movement monitoring

3\. \*\*View Details\*\*: Click on any grid cell to see detailed block information

4\. \*\*Crypto Operations\*\*: Register blocks as crypto users and perform transactions

### Camera Controls

\- Toggle between camera feeds

\- Enable/disable specific signatures (colors)

\- Filter blocks by road/track/plain surfaces

## 🔌 API Integration

### Block Data Format

\`\`\`dart

{

"uuid": "string",

"timestamp": "ISO8601",

"signature": 1-4,

"camera": "string",

"raw\_x": number,

"raw\_y": number,

"cell": "x,y",

"start\_tracking": boolean

}

\`\`\`

### Cryptocurrency Operations

- User registration with wallet creation

- PIN-based authentication

- Coin transfers between addresses

- Balance checking and blockchain loading

## 🧪 Testing

Run the test suite:

\`\`\`bash

flutter test

\`\`\`

For specific test files:

\`\`\`bash

flutter test test/block\_tracker\_test.dart

flutter test test/pixy\_service\_test.dart

\`\`\`

## 📊 Performance

- \*\*60 FPS Animation\*\*: Smooth block movement animations

- \*\*Efficient Rendering\*\*: Optimized grid rendering with reusable widgets

- \*\*Memory Management\*\*: Proper disposal of controllers and listeners

- \*\*Network Optimization\*\*: Efficient API calls with error handling

## 🐛 Troubleshooting

### Common Issues

1\. \*\*Camera feed not loading\*\*: Check API endpoint connectivity

2\. \*\*Blocks not appearing\*\*: Verify signature filters and camera settings

3\. \*\*Crypto operations failing\*\*: Ensure backend services are running

### Debug Mode

Enable debug logging:

\`\`\`dart

void main() {

debugPrint = (String? message, {int? wrapWidth}) {

// Custom debug output

};

runApp(const BrickMMOApp());

}

\`\`\`