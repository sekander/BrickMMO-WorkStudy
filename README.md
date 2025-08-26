# BrickMMO Pixy Vision System

A comprehensive computer vision system for detecting and tracking LEGO blocks using Pixy2 cameras, with a full-stack implementation including C++ detection, Flask backend, and Flutter frontend.

## 📋 System Overview

This system provides real-time LEGO block detection, tracking, and visualization for the BrickMMO ecosystem. It consists of three main components:

1. **C++ Pixy2 Detection Application** - Camera interface and block detection
2. **Flask Backend API** - Data processing, storage, and image handling
3. **Flutter Frontend** - Real-time visualization and user interface

## 🏗️ Architecture

```
Physical Layer:    [Pixy2 Cameras] → USB → [Computer]
Detection Layer:   [C++ Application] → HTTP → [Flask Backend]
Data Layer:        [MongoDB] ←→ [Flask Backend] ←→ [Flutter Frontend]
Presentation:      [Flutter Web/Mobile App] → Users
```

## 🚀 Quick Start

### Prerequisites
- Ubuntu/Linux system
- Python 3.7+
- Flutter SDK
- MongoDB
- Pixy2 cameras

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd BrickMMO-WorkStudy
   ```

2. **Set up the C++ detection application**
   ```bash
   cd pixy_cpp
   sudo apt-get install libcurl4-openssl-dev rapidjson-dev
   ./install_pixy_dependencies.sh
   g++ -o pixy_detector main.cpp -lpixy2 -lcurl -std=c++11
   ```

3. **Set up the Flask backend**
   ```bash
   cd ../back-end
   pip install -r requirements.txt
   mkdir -p static/converted_imagesi/regular static/converted_imagesi/clean
   ```

4. **Set up the Flutter frontend**
   ```bash
   cd ../front-end
   flutter pub get
   ```

5. **Configure environment**
   - Update backend URL in `pixy_cpp/main.cpp`
   - Configure MongoDB connection in `back-end/app.py`
   - Set API endpoints in `front-end/lib/services/`

### Running the System

1. **Start MongoDB**
   ```bash
   sudo systemctl start mongod
   ```

2. **Launch the backend**
   ```bash
   cd back-end
   python app.py
   ```

3. **Run the detection application**
   ```bash
   cd pixy_cpp
   sudo ./pixy_detector
   ```

4. **Start the frontend**
   ```bash
   cd front-end
   flutter run
   ```

## 📊 Component Details

### C++ Pixy Detection Application

**Features:**
- Dual camera support with simultaneous processing
- Real-time color signature detection
- Configurable filtering by position and size
- JSON data formatting with coordinate adjustment
- HTTP POST integration to backend

**Key Configuration:**
```cpp
// Camera parameters
get_blocks_custom(pixy, "PC-CAMERA 1: ", 0, 207, 0, 0, jsonOutput);

// Backend URL
const char* backend_url = "192.168.2.87:5012/json_0";
```

### Flask Backend API

**Endpoints:**
- `POST /json_0`, `/json_1` - Receive detection data from cameras
- `GET /get_json_0`, `/get_json_1` - Retrieve processed data
- `POST /insert_detection` - Store new detections
- `POST /update_tracking` - Update block positions
- `POST /upload` - Process PPM images
- `GET /latest.png` - Serve processed images

**Data Processing:**
- Fisheye distortion correction
- Coordinate transformation
- MongoDB storage with timestamps
- Image conversion (PPM to PNG)

### Flutter Frontend

**Features:**
- Real-time block visualization on city grid
- Interactive block tracking and registration
- Multi-camera support with signature filtering
- Cryptocurrency integration for block transactions
- Responsive design for desktop and mobile

**Architecture:**
- Service-based design with separate modules for:
  - Block tracking and prediction
  - Camera communication
  - Cryptocurrency operations
  - Map data handling

## 🔧 Configuration Guide

### Camera Calibration

Adjust these parameters in `back-end/app.py`:
```python
# Camera matrix parameters
w = 316  # Frame width
h = 208  # Frame height
centre = (w // 2, h // 2)

# Distortion coefficients (adjust for your camera)
dist_coeffs = np.array([-0.2, 0.1, 0, 0], dtype=np.float32)
```

### MongoDB Setup

1. Install MongoDB
2. Update connection string in `back-end/app.py`:
```python
client = MongoClient("mongodb://localhost:27017/")
```

### Network Configuration

Update these URLs for your environment:

**In C++ application:**
```cpp
const char* backend_url = "your-server-ip:5012/json_0";
```

**In Flutter frontend:**
```dart
// Update base URLs in service files
const String PIXY_API_BASE = "http://your-server-ip:5012";
```

## 🎮 Usage Instructions

### Block Detection and Tracking

1. **Position cameras** to cover the target area
2. **Configure signatures** in Pixy2 for your LEGO colors
3. **Launch the system** following the startup sequence
4. **View detected blocks** in the Flutter interface
5. **Register blocks** by capturing them in the system
6. **Track movement** using the predictive tracking algorithm

### Image Processing

1. Send PPM images to `/upload` endpoint
2. Access processed images at `/latest.png?folder=clean`
3. View original images at `/latest.png?folder=regular`

### Data Management

1. View all detections: `GET /detections`
2. Query by ID: `GET /detections/by-custom-id/<id>`
3. Monitor real-time data: `GET /get_json_0` or `/get_json_1`

## 🐛 Troubleshooting

### Common Issues

1. **Camera not detected**
   - Check USB connections
   - Run with `sudo` for device access
   - Verify libpixyusb2 installation

2. **HTTP connection errors**
   - Verify backend URL configuration
   - Check firewall settings
   - Confirm backend is running

3. **Image processing failures**
   - Verify OpenCV and Pillow installation
   - Check directory permissions for image storage

4. **MongoDB connection issues**
   - Confirm MongoDB service is running
   - Check connection string format

### Debug Mode

Enable debug output in each component:

**C++ Application:** Compile with `-DDEBUG` flag

**Flask Backend:** 
```python
app.run(host="0.0.0.0", port=5012, debug=True)
```

**Flutter Frontend:** 
```bash
flutter run --debug
```

## 🔒 Security Considerations

1. **Add authentication** to API endpoints for production use
2. **Enable HTTPS** for all communications
3. **Implement input validation** on all endpoints
4. **Add rate limiting** to prevent abuse
5. **Secure MongoDB** with authentication and access controls

## 📈 Performance Optimization

### For High Throughput:

1. **C++ Application:**
   - Adjust frame processing rate
   - Optimize JSON serialization
   - Implement connection pooling

2. **Flask Backend:**
   - Use production WSGI server (Gunicorn)
   - Implement database connection pooling
   - Add caching for frequently accessed data

3. **Flutter Frontend:**
   - Optimize widget rebuilds
   - Implement efficient grid rendering
   - Use isolates for heavy computations

## 🤝 Contributing

1. Follow the established architecture patterns
2. Maintain consistent code style
3. Add tests for new functionality
4. Update documentation for changes
5. Test across all system components

## 📄 License

This project uses multiple open-source components with their respective licenses:
- libpixyusb2 (Pixy2 SDK)
- RapidJSON (MIT License)
- libcurl (MIT License)
- Flask (BSD License)
- Flutter (BSD License)

Please ensure compliance with all applicable licenses.

## 🆘 Support

For issues with:

- **Pixy2 hardware**: Contact Charmed Labs
- **C++ detection application**: Check issues in pixy_cpp
- **Backend API**: Check issues in back-end
- **Frontend application**: Check issues in front-end

## 🚀 Future Enhancements

1. Machine learning for improved block recognition
2. 3D position tracking with multiple cameras
3. Advanced blockchain integration
4. Mobile app for remote monitoring
5. Automated calibration system
6. Multi-language support
7. Plugin architecture for extensions

---

*This system is part of the BrickMMO project - building the future of interactive LEGO-based environments.*

