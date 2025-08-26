# Pixy2 Backend API Server


A Flask-based backend server that receives, processes, and stores data from Pixy2 cameras. This server provides API endpoints for receiving detection data, storing it in MongoDB, and serving processed images.


## Features


- **RESTful API**: Multiple endpoints for receiving and retrieving Pixy2 detection data
- **MongoDB Integration**: Stores detection data with timestamps and camera information
- **Image Processing**: Converts PPM images to PNG and applies fisheye correction
- **CORS Support**: Cross-origin resource sharing enabled for frontend integration
- **Dual Camera Support**: Handles data from two separate cameras (json_0 and json_1 endpoints)


## API Endpoints


### Data Reception
- `POST /json_0` - Receive detection data from camera 1
- `POST /json_1` - Receive detection data from camera 2
- `POST /insert_detection` - Insert a new detection record
- `POST /update_tracking` - Update tracking data for an existing detection


### Data Retrieval
- `GET /get_json_0` - Retrieve processed data from camera 1
- `GET /get_json_1` - Retrieve processed data from camera 2
- `GET /detections` - Get all detection records
- `GET /detections/by-custom-id/<id>` - Get detection by custom ID


### Image Handling
- `POST /upload` - Upload PPM images for processing
- `GET /latest.png` - Retrieve the latest processed image
- `GET /video` - Serve MP4 video file


## Installation


### Prerequisites
- Python 3.7+
- MongoDB
- Flask and required dependencies


### Setup
1. Install required Python packages:
```bash
pip install flask flask-cors pymongo opencv-python pillow
```


2. Ensure MongoDB is running on the configured host (default: 192.168.2.87:27017)


3. Create the necessary directories:
```bash
mkdir -p static/converted_imagesi/regular
mkdir -p static/converted_imagesi/clean
```


4. Run the application:
```bash
python app.py
```


The server will start on `0.0.0.0:5012`


## Configuration


### MongoDB Connection
Edit the connection string in the code:
```python
client = MongoClient("mongodb://your-mongodb-host:27017/")
```


### Image Processing Parameters
Adjust camera calibration parameters as needed:
```python
# Camera matrix parameters
w = 316  # Width
h = 208  # Height
centre = (w // 2, h // 2)


# Distortion coefficients (adjust based on your camera)
dist_coeffs = np.array([-0.2, 0.1, 0, 0], dtype=np.float32)
```


## Data Format


### Detection Data Structure
```json
{
  "camera": "PC-CAMERA 1: ",
  "timestamp": "2023-11-15T12:00:00.000Z",
  "signature": 1,
  "x": 150.5,
  "y": 100.2,
  "width": 30,
  "height": 25,
  "detection_id": "unique-id-here"
}
```


### API Response Format
Successful requests typically return:
```json
{
  "message": "Operation successful",
  "data": { ... }
}
```


## Image Processing


The server handles PPM image uploads and:
1. Converts them to PNG format
2. Applies fisheye distortion correction
3. Saves both original and processed images
4. Makes them available via the `/latest.png` endpoint


### Accessing Processed Images
- Regular images: `/latest.png?folder=regular`
- Cleaned images: `/latest.png?folder=clean`


## Usage Examples


### Sending Detection Data
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"signature":1,"x":150,"y":100,"width":30,"height":25,"camera":"PC-CAMERA 1:","detection_id":"12345"}' \
  http://localhost:5012/insert_detection
```


### Retrieving All Detections
```bash
curl http://localhost:5012/detections
```


### Uploading an Image
```bash
curl -X POST --data-binary @image.ppm http://localhost:5012/upload
```


## Troubleshooting


### Common Issues
1. **MongoDB Connection Errors**: Verify MongoDB is running and accessible
2. **Image Processing Failures**: Check that OpenCV and Pillow are properly installed
3. **CORS Errors**: Ensure frontend requests include appropriate headers


### Debug Mode
Run with debug enabled for detailed error information:
```python
app.run(host="0.0.0.0", port=5012, debug=True)
```


## Security Considerations


1. **Authentication**: Currently none implemented - add authentication for production use
2. **Input Validation**: Add more robust validation for all endpoints
3. **Rate Limiting**: Implement to prevent abuse
4. **HTTPS**: Use HTTPS in production environments


## Monitoring


Check server status by visiting `http://localhost:5012/` in a browser or using:
```bash
curl http://localhost:5012/
```


## Extension Ideas


1. Add user authentication and authorization
2. Implement WebSocket support for real-time updates
3. Add image analysis and object recognition
4. Create dashboard for visualizing detection data
5. Add data export functionality


## License


This project is built with Flask and other open-source libraries. Please ensure compliance with their respective licenses.

