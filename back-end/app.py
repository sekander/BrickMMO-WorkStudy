from flask import Flask, request, jsonify, send_file, Response
from flask_cors import CORS
from pymongo import MongoClient
import cv2
import numpy as np
from PIL import Image
import io
import json
import os

import datetime


# MonogoDB connection
client = MongoClient("mongodb://192.168.2.87:27017/")
db = client["pixycam"]
collection = db["detections"]

app = Flask(__name__)

UPLOAD_FOLDER_REGULAR = 'static/converted_imagesi/regular'
os.makedirs(UPLOAD_FOLDER_REGULAR, exist_ok=True)

UPLOAD_FOLDER_CLEAN = 'static/converted_imagesi/clean'
os.makedirs(UPLOAD_FOLDER_CLEAN, exist_ok=True)

# Enable CORS for all routes
CORS(app)

# Global variable to store the processed JSON data
#processed_data = {}
processed_data_0 = {}
processed_data_1 = {}

# Store last converted PNG in memory
latest_png = io.BytesIO()

all_detections = {}


@app.route('/')
def home():
    return 'Hello, Flask!'


def process_pixy_json(data, camera_id):
    """
    Process incoming JSON from Pixy camera, apply undistortion, and return cleaned data.
    """
    if isinstance(data, list):
        data = data[0]  # Flatten list input if necessary

    if "signature" not in data:
        return None, {"message": "OTHER JSON received successfully"}

    try:
        sig = data['signature']
        j_x, j_y = data['x'], data['y']
        j_w, j_h = data['width'], data['height']

        # Camera parameters
        w, h = 316, 208
        centre = (w // 2, h // 2)

        camera_matrix = np.array([
            [w, 0, centre[0]],
            [0, w, centre[1]],
            [0, 0, 1]
        ], dtype=np.float32)

        dist_coeffs = np.array([-0.2, 0.1, 0, 0], dtype=np.float32)

        new_camera_matrix = cv2.getOptimalNewCameraMatrix(
            camera_matrix, dist_coeffs, (w, h), 1, (w, h)
        )[0]

        point = np.array([[j_x, j_y]], dtype=np.float32)
        undistorted_points = cv2.undistortPoints(
            point, camera_matrix, dist_coeffs, P=new_camera_matrix
        )

        u_x, u_y = map(float, undistorted_points[0][0])

        processed = {
            "signature": sig,
            "x": u_x,
            "y": u_y,
            "w": j_w,
            "h": j_h
        }

        # Store results in the right global variable
        if camera_id == 0:
            global processed_data_0
            processed_data_0 = processed
        elif camera_id == 1:
            global processed_data_1
            processed_data_1 = processed

        print(f"Camera {camera_id} processed:", processed)

        return processed, {
            "message": "PIXY JSON received successfully",
            **processed
        }

    except json.JSONDecodeError as e:
        return None, {"message": f"ERROR: JSON parsing failed ({e})"}
    except Exception as e:
        return None, {"message": f"ERROR: Unexpected error ({e})"}


@app.route('/json_0', methods=['POST'])
def handle_json_0():
    data = request.get_json()
    print("Received JSON (cam0):", data)
    _, response = process_pixy_json(data, camera_id=0)
    return jsonify(response), 200


@app.route('/json_1', methods=['POST'])
def handle_json_1():
    data = request.get_json()
    print("Received JSON (cam1):", data)
    _, response = process_pixy_json(data, camera_id=1)
    return jsonify(response), 200

@app.route('/get_json_0', methods=['GET'])
def get_json_0():
    # Return the processed JSON data
    #if processed_data:
    if processed_data_0 is not None:
        print(processed_data_0);
        return jsonify(processed_data_0), 200
    else:
        return jsonify({
            "message": "No data available"
        }), 404

@app.route('/get_json_1', methods=['GET'])
def get_json_1():
    # Return the processed JSON data
    #if processed_data:
    if processed_data_1 is not None:
        print(processed_data_1);
        return jsonify(processed_data_1), 200
    else:
        return jsonify({
            "message": "No data available"
        }), 404


@app.route('/insert_detection', methods=['POST'])
def insert_detection():
    try:
        data = request.get_json()

        # Validate required fields
        required_fields = ['signature', 'x', 'y', 'width', 'height', 'camera', 'detection_id']
        if not all(field in data for field in required_fields):
            return jsonify({"error": "Missing required fields"}), 400

        # Prepare the document
        document = {
            "camera": data['camera'],
            "timestamp": datetime.datetime.utcnow(),
            "signature": data['signature'],
            "x": data['x'],
            "y": data['y'],
            "width": data['width'],
            "height": data['height'],
            "detection_id": data['detection_id']
        }

        # Insert into MongoDB
        result = collection.insert_one(document)

        detection_id = data['detection_id']
        data['timestamp'] = int(time.time() * 1000)
	
        all_detections[detection_id] = data

        return jsonify({
            "message": "Detection inserted successfully",
            "inserted_id": str(result.inserted_id)
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# NEW ROUTE: Get all documents from the 'detections' collection
@app.route('/detections', methods=['GET'])
def get_all_detections():
    try:
        # Fetch all documents from the 'detections' collection
        # Using a list comprehension to convert ObjectId to string for JSON serialization
        detections = []
        for doc in collection.find():
            doc['_id'] = str(doc['_id']) # Convert ObjectId to string
            detections.append(doc)
        return jsonify(detections), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# NEW ROUTE: Filter detections by your custom 'detection_id' (UUID)
@app.route('/detections/by-custom-id/<string:custom_detection_id>', methods=['GET'])
def get_detection_by_custom_id(custom_detection_id):
    try:
        # Find a single document by your custom 'detection_id' field
        detection = collection.find_one({"detection_id": custom_detection_id})

        if detection:
            detection['_id'] = str(detection['_id']) # Convert ObjectId to string
            return jsonify(detection), 200
        else:
            return jsonify({"message": "Detection not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/update_tracking', methods=['POST'])
def update_tracking():
    try:
        data = request.get_json()

        required_fields = ['detection_id', 'x', 'y', 'timestamp']
        if not all(field in data for field in required_fields):
            return jsonify({"error": "Missing required fields"}), 400

        detection_id = data['detection_id']

        # Update existing document in the "detections" collection
        result = collection.update_one(
            {"detection_id": detection_id},
            {
                "$set": {
                    "x": data['x'],
                    "y": data['y'],
                    "last_updated": data['timestamp']
                }
            }
        )

        if result.matched_count == 0:
            return jsonify({
                "message": f"No document found with detection_id '{detection_id}'"
            }), 404

        return jsonify({
            "message": "Tracking data updated successfully",
            "detection_id": detection_id
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/upload", methods=["POST"])
def upload_ppm():
	global latest_png
	
	# Read raw PPM data
	ppm_data = request.data
	if not ppm_data:
		return "No data received", 400
	try:
	# Convert raw PPM to PNG in-memory
		ppm_image = Image.open(io.BytesIO(ppm_data))

		#latest_png = io.BytesIO()
		#ppm_image.save(latest_png, format="PNG")
		#latest_png.seek(0)
		# Generate a unique filename based on timestamp
		timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
		filename = f"image_{timestamp}.png"
		filepath = os.path.join(UPLOAD_FOLDER_REGULAR, filename)

		# Save to disk
		ppm_image.save(filepath, format="PNG")

		png_bytes = io.BytesIO()
		png_bytes.seek(0)

		# Convert to OpenCV image
		file_bytes = np.asarray(bytearray(png_bytes.read()), dtype=np.uint8)
		#image = cv2.imdecode(file_bytes, cv2.IMREAD_UNCHANGED)
		#image = cv2.imdecode(ppm_data, cv2.IMREAD_UNCHANGED)
		#image = cv2.imdecode(ppm_image, cv2.IMREAD_UNCHANGED)
		image = cv2.imread(filepath, cv2.IMREAD_UNCHANGED)

		if image is None:
		    return jsonify({"error": "Failed to decode image"}), 500

		# Check if image has alpha channel
		if image.shape[2] == 4:
		    bgr_image = image[:, :, :3]
		    alpha_channel = image[:, :, 3]
		else:
		    bgr_image = image
		    alpha_channel = None

		h, w = bgr_image.shape[:2]

		# Define camera matrix and distortion coefficients
		focal_length = w
		center = (w // 2, h // 2)
		camera_matrix = np.array([
		    [focal_length, 0, center[0]],
		    [0, focal_length, center[1]],
		    [0, 0, 1]
		], dtype=np.float32)

		# Example distortion coefficients; adjust as needed
		dist_coeffs = np.array([-0.2, 0.1, 0, 0], dtype=np.float32)

		# Compute new camera matrix
		new_camera_matrix, roi = cv2.getOptimalNewCameraMatrix(
		    camera_matrix, dist_coeffs, (w, h), 1, (w, h)
		)

		# Undistort the image
		undistorted_bgr = cv2.fisheye.undistortImage(
		    bgr_image, camera_matrix, dist_coeffs, Knew=new_camera_matrix
		)

		# Crop the image using the ROI
		x, y, w_roi, h_roi = roi
		undistorted_bgr = undistorted_bgr[y:y+h_roi, x:x+w_roi]

		# Merge alpha channel back if present
		if alpha_channel is not None:
		    alpha_cropped = alpha_channel[y:y+h_roi, x:x+w_roi]
		    undistorted_image = cv2.merge([undistorted_bgr, alpha_cropped])
		else:
		    undistorted_image = undistorted_bgr

		# Generate unique filename
		timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
		filename = f"undistorted_{timestamp}.png"
		filepath = os.path.join(UPLOAD_FOLDER_CLEAN, filename)

		# Save the undistorted image
		cv2.imwrite(filepath, undistorted_image)

		return "Image received and converted", 200
	except Exception as e:
		return f"Conversion failed: {str(e)}", 500


#@app.route("/latest.png")
#def get_latest_image():
#    if latest_png.getbuffer().nbytes == 0:
#        #return "No image available", 404
#        return jsonify({
#            "message": "No data available"
#        }), 404
#    latest_png.seek(0) #Reset the stream position to the beginning
#    return send_file(latest_png, mimetype="image/png")



@app.route("/latest.png")
def get_latest_image():
    base_folder = 'static/converted_imagesi'
    folder_param = request.args.get('folder', 'regular').lower()

    # Map valid folder names to their paths
    folder_map = {
        'regular': os.path.join(base_folder, 'regular'),
        'clean': os.path.join(base_folder, 'clean')
    }

    # Validate the folder parameter
    if folder_param not in folder_map:
        return jsonify({"error": "Invalid folder parameter. Use 'regular' or 'clean'."}), 400

    image_folder = folder_map[folder_param]

    try:
        # List PNG files in the selected folder
        png_files = [f for f in os.listdir(image_folder) if f.lower().endswith(".png")]
        if not png_files:
            return jsonify({"message": f"No PNG files found in the '{folder_param}' folder."}), 404

        # Find the most recently modified PNG file
        latest_file = max(
            png_files,
            key=lambda f: os.path.getmtime(os.path.join(image_folder, f))
        )
        latest_path = os.path.join(image_folder, latest_file)

        return send_file(latest_path, mimetype="image/png")

    except Exception as e:
        return jsonify({"error": str(e)}), 500


#@app.route("/latest.png")
#def get_latest_image():
#    image_folder = 'static/converted_images'
#    try:
#        # List PNG files and sort by last modified time
#        png_files = [f for f in os.listdir(image_folder) if f.endswith(".png")]
#        if not png_files:
#            return jsonify({"message": "No data available"}), 404
#
#        latest_file = max(
#            png_files,
#            key=lambda f: os.path.getmtime(os.path.join(image_folder, f))
#        )
#        latest_path = os.path.join(image_folder, latest_file)
#
#        return send_file(latest_path, mimetype="image/png")
#
#    except Exception as e:
#        return jsonify({"error": str(e)}), 500

# Endpoint to serve the MP4 video file
@app.route('/video')
def video():
    video_path = os.path.join(os.getcwd(), 'output.mp4')
    return send_file(video_path, mimetype='video/mp4')

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5012, debug=True)
