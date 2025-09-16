# BrickMMO WorkStudy - Pixy2 Camera Tracking System

## Navigation Guide

The project root is `BrikMMo-WorkStudy`. Here's how to navigate to the relevant files:

```
BrikMMo-WorkStudy/
└── pixy_cpp/
    └── pixy_cpp_source/
        └── src/
            └── host/
                └── libpixyusb2_examples/
                    └── get_blocks_cpp_demo/
                        ├── capture-json-cam.cpp    # Single-threaded version
                        ├── multi-thread-cam.cpp    # Multi-threaded version
                        └── Makefile               # Build configuration
```

From the terminal, navigate to:
```bash
cd ~/C0de/GIT/BrickMMo-WorkStudy/pixy_cpp/pixy_cpp_source/src/host/libpixyusb2_examples/get_blocks_cpp_demo
```

## Makefile Usage and Modification

### Building the Project:
```bash
make clean    # Clean previous builds
make          # Build the project
```

### Modifying the Makefile:

1. **Change source file** (default: capture-json-cam.cpp):
   ```makefile
   SRCS=multi-thread-cam.cpp  # Switch to multi-threaded version
   ```

2. **Change output executable name**:
   ```makefile
   # Change the target name
   get_blocks: $(OBJS)
       $(CXX) $(LDFLAGS) -o camera-tracker $(OBJS) $(LDLIBS)  # New name
   ```

3. **Add include paths**:
   ```makefile
   CPPFLAGS=-g -fpermissive -I/usr/include/libusb-1.0 -I../../libpixyusb2/include -I../../arduino/libraries/Pixy2 -I/new/include/path
   ```

4. **Add libraries**:
   ```makefile
   LDLIBS=../../../../build/libpixyusb2/libpixy2.a -lusb-1.0 -lcurl -lpthread -lnewlib
   ```

5. **Build for different source files**:
   ```bash
   make SRCS=multi-thread-cam.cpp  # Build specific file without editing Makefile
   ```

## Code Explanation: capture-json-cam.cpp

### Overview
Single-threaded application that connects to Pixy2 cameras, detects colored objects, and sends JSON data to a backend server.

### Key Functionality:
1. **Initialization**: Connects to one or two Pixy2 cameras with error handling
2. **Object Detection**: Uses color connected components algorithm to detect objects
3. **Data Processing**: Filters objects by Y-position and applies camera-specific coordinate offsets
4. **JSON Formatting**: Uses RapidJSON to create structured data payloads
5. **HTTP Transmission**: Sends data to backend server using libcurl

### Workflow:
1. Initialize cameras and check connections
2. Enter continuous loop:
   - Query both cameras for detected blocks
   - Filter and process the data
   - Format into JSON structure
   - Send to backend via HTTP POST
   - Repeat until interrupted

### Key Features:
- Graceful shutdown handling (CTRL+C support)
- Configurable backend URL
- Camera-specific coordinate adjustments
- Error handling for camera connections

## Code Explanation: multi-thread-cam.cpp

### Overview
Enhanced multi-threaded version that parallelizes camera operations for improved performance.

### Key Enhancements Over Single-Threaded Version:
1. **Parallel Processing**: Uses separate threads for:
   - Data transmission to backend
   - Frame capture from each camera
   - Image processing and saving

2. **Additional Functionality**:
   - Raw frame capture and demosaicing
   - PPM image file saving
   - Support for up to 4 cameras
   - Better resource management

### Thread Structure:
1. **Transmit Thread**: Handles JSON data creation and HTTP transmission
2. **Frame Capture Threads**: Each camera has a dedicated thread for image capture
3. **Main Thread**: Manages overall application flow and thread coordination

### Advanced Features:
- Frame counter for sequential image saving
- Bayer to RGB conversion (demosaicing)
- Configurable frame capture intervals
- Dynamic camera activation tracking
- Better error handling for frame capture

### Workflow:
1. Initialize all available cameras
2. Launch parallel threads for different tasks
3. Coordinate data sharing between threads
4. Clean shutdown with proper thread termination

### Performance Benefits:
- Non-blocking operations: HTTP transmission doesn't delay frame capture
- Better CPU utilization across multiple cores
- Higher throughput for multi-camera setups
- Responsive control even during heavy processing

Both versions serve the same core purpose but the multi-threaded version offers significantly better performance for production environments with multiple cameras or high data volume requirements.
