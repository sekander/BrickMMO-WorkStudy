Here’s a simple README in Markdown format for the provided Flask project:

```markdown
# Flask Camera Distortion Correction API

This project is a Flask-based API that handles JSON input containing camera data, processes the data to correct for fisheye distortion, and returns the transformed data in JSON format.

## Features

- **Home Route (`/`)**: A simple route that returns a "Hello, Flask!" message.
- **JSON Route (`/json`)**: A POST endpoint that accepts JSON input containing signature and camera data (x, y, width, height). The API performs distortion correction using OpenCV and returns the corrected values.

## Technologies

- **Flask**: A micro web framework for Python.
- **OpenCV**: Used for camera distortion correction.
- **NumPy**: For handling matrix operations.

## Installation

1. Clone this repository or download the code.
   
   ```bash
   git clone <repository-url>
   ```

2. Install the required dependencies.

   ```bash
   pip install flask opencv-python numpy
   ```

3. Run the Flask app.

   ```bash
   python app.py
   ```

   The app will run on `http://0.0.0.0:5000/`.

## API Endpoints

### 1. Home (`GET /`)
- **Description**: Returns a simple welcome message.
- **Response**:
  ```json
  {
    "message": "Hello, Flask!"
  }
  ```

### 2. Handle JSON (`POST /json`)
- **Description**: Accepts JSON data containing camera-related information and a signature, then performs distortion correction using OpenCV and returns the transformed points.
- **Request**:
  The request body should be a JSON object containing the following keys:
  - `signature` (string): The signature for the points.
  - `x` (integer): The x-coordinate of the point.
  - `y` (integer): The y-coordinate of the point.
  - `width` (integer): The width of the object.
  - `height` (integer): The height of the object.

  Example request body:
  ```json
  {
    "signature": "abc123",
    "x": 100,
    "y": 150,
    "width": 50,
    "height": 80
  }
  ```

- **Response**:
  On success, the API will return the transformed coordinates (undistorted) as JSON:
  ```json
  {
    "message": "PIXY JSON received successfully",
    "signature": "abc123",
    "x": 110.5,
    "y": 160.3,
    "w": 50,
    "h": 80
  }
  ```

  If there’s an error in processing the JSON or if the `signature` key is missing, the API will return an error message:
  ```json
  {
    "message": "ERROR: JSON"
  }
  ```

  Or if the signature key is missing:
  ```json
  {
    "message": "OTHER JSON received successfully"
  }
  ```

## Error Handling

- **JSONDecodeError**: If the input JSON cannot be parsed.
- **General Exception**: Catches any unexpected errors during the processing.

## Running the Application

To run the application locally, simply execute:

```bash
python app.py
```

This will start the Flask server on port 5000. You can test the endpoints using a tool like Postman or cURL.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
```

This README provides a clear overview of the project, its functionality, and how to set up and use it.

