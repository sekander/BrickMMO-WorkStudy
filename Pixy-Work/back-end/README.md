# Work-Study Project: BrickMMO Smart City Development Platform

## Introduction

This project involves working with the BrickMMO Smart City Development Platform, focusing on programming various assets related to the platform. Specifically, you will be working with the BrickMMO Console and several public-facing websites. The position offers a unique opportunity to gain experience in web development and working with LEGO Mindstorms EV3 systems.

## Job Description

As a work-study student in this role, you will be assisting with the development of both the backend and frontend of the BrickMMO platform. Programming languages you will be using include HTML, CSS, JavaScript, PHP, Node.js, and Python. You will also work with database technologies such as MySQL and MongoDB.

### Key tasks will include:
- Developing and maintaining the BrickMMO Console.
- Contributing to public-facing websites using technologies like HTML, CSS, JavaScript, PHP, and Node.js.
- Interacting with MySQL and MongoDB databases for data management and storage.
- Working with libraries and frameworks like W3.CSS, Bootstrap, React, and Laravel.

---

# Task 1: Getting Started with LEGO Mindstorms EV3 and Pixy2

To help you get started, there are several useful links and tasks:

## Useful Links:
- **[LEGO Mindstorms Python](https://education.lego.com/en-us/start/mindstorms-ev3/#Setting-Up)**: Setting up LEGO Mindstorms EV3 with Python
- **[VS Code EV3 Extension](https://marketplace.visualstudio.com/items?itemName=lego-education.ev3-micropython)**: EV3 MicroPython Extension for VS Code
- **[Step-by-Step Instructions](https://docs.google.com/document/d/14HTwoAp6patQz-ojXtV43xSC5o3aIVUsw206isiXGsU/edit?usp=sharing)**: EV3 Setup Instructions
- **[Pixy2 for LEGO](https://pixycam.com/pixy2-lego/)**: Pixy2 Camera for LEGO Mindstorms

## Recommended Tasks:
1. **Make a motor move when a button is pressed**:
    - Use the tutorial to control a motor using a button press on the EV3.
    - [EV3 Motor Example on GitHub](https://github.com/codeadamca/ev3-motor)

2. **Read Camera Data**:
    - Get familiar with how to read data from the Pixy2 camera.

3. **Train the Camera to Track a Red Square**:
    - Use Pixy2's object detection capabilities to track a red square.

4. **Remove Fish-eye Effect**:
    - Work on eliminating the distortion from the Pixy2 camera's image to improve object recognition.

---

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


2. Run the Flask app.

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
- **Request**: The request body should be a JSON object containing the following keys:
    - `signature` (string): The signature for the points.
    - `x` (integer): The x-coordinate of the point.
    - `y` (integer): The y-coordinate of the point.
    - `width` (integer): The width of the object.
    - `height` (integer): The height of the object.

    **Example request body**:
    ```json
    {
      "signature": "abc123",
      "x": 100,
      "y": 150,
      "width": 50,
      "height": 80
    }
    ```

- **Response**: On success, the API will return the transformed coordinates (undistorted) as JSON:
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

    Or if the `signature` key is missing:
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


This will start the Flask server on port 5000. You can test the endpoints using a tool like Postman or cURL.

