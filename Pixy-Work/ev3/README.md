# EV3 Pixy2 Object Detection and API Communication

This project allows an EV3 robot to detect objects using a Pixy2 camera, process the detected data, and send it to a remote API endpoint. The robot interacts with a motor and touch sensor while sending object detection data in JSON format.

## Features

- **Pixy2 Object Detection**: Captures the signature, coordinates, width, and height of detected objects.
- **Motor and Sensor Interaction**: Controls an EV3 motor based on sensor input.
- **API Communication**: Sends the detected object data to a remote server using HTTP POST requests.
- **Graceful Shutdown**: Stops the program when the center button on the EV3 is pressed.

## Technologies

- **EV3 MicroPython**: For interacting with the EV3 hardware.
- **Pixy2**: A camera module used for object detection.
- **urequests**: Used for making HTTP requests to a remote API.
- **pybricks**: A library for controlling LEGO EV3 motors, sensors, and other hardware.

## Prerequisites

1. **Hardware**:
   - LEGO EV3 Brick
   - Pixy2 camera module
   - Motor connected to Port A
   - Touch sensor connected to Port 1

2. **Software**:
   - Pybricks MicroPython installed on the EV3 brick
   - Access to the Pixy2 camera library for EV3
   - A running server at `http://192.168.2.18:5000/json` to receive the data

## Installation

1. Clone or download the project.
   
   ```bash
   git clone <repository-url>


- Install the required dependencies (Pybricks MicroPython libraries and Pixy2 library for EV3).
- Flash the firmware to the EV3 Brick and transfer the script to the robot.

## Code Explanation

### Initialization

The script initializes the following:

- **EV3 Brick**: Sets up the speaker volume and beeps to signify the start.
- **Pixy2 Camera**: Initializes the Pixy2 camera connected to port 4 and retrieves its version and frame resolution.
- **Motor and Touch Sensor**: Initializes a motor on Port A and a touch sensor on Port 1. The motor speed is controlled by the touch sensor state.

### Main Loop

- **Pixy2 Data**: The `read_pixy_data` function retrieves the signature, x/y coordinates, width, and height of the detected object from the Pixy2 camera.
- **API Request**: The extracted data is sent as a JSON POST request to the server.
- **Graceful Exit**: The program checks if the center button on the EV3 brick is pressed, which stops the program and turns off the light.

### Function Definitions

- `read_pixy_data()`: Fetches the data from the Pixy2 camera, formats it into a JSON structure, and returns the data.
  
- **HTTP POST**: Sends the captured object data to the endpoint `http://192.168.2.18:5000/json`.

### Error Handling

- **No Blocks Detected**: If no objects are detected by the Pixy2 camera, the system will return an error message in JSON format: `{ "error": "No blocks detected" }`.
  
- **API Response Check**: After sending the data, the response from the server is checked. If the response status is 200 (OK), the result is printed.

## Running the Script

1. Upload the script to the EV3 Brick.
2. Run the script on the EV3 Brick:

   ```bash
   python ev3_pixy2.py

3. The robot will start detecting objects with the Pixy2 camera and send data to the server.
4. To stop the program, press the center button on the EV3.
