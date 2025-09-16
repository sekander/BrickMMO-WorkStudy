import sys
import os
import cv2
import numpy as np

# Check if an image path is provided as a command-line argument
if len(sys.argv) != 2:
    print("Usage: python script.py <image_path>")
    sys.exit(1)

# Load the fisheye PNG image with alpha channel
image_path = sys.argv[1]
image = cv2.imread(image_path, cv2.IMREAD_UNCHANGED)

# Check if the image was loaded successfully
if image is None:
    print(f"Error: Unable to load image '{image_path}'")
    sys.exit(1)

# Check if the image has an alpha channel (4 channels: RGBA)
if image.shape[2] == 4:
    # Split the image into RGB and Alpha channels
    bgr_image = image[:, :, :3]  # RGB channels
    alpha_channel = image[:, :, 3]  # Alpha channel
else:
    # If no alpha channel, just work with the RGB image
    bgr_image = image
    alpha_channel = None

# Get image dimensions
h, w = bgr_image.shape[:2]

# Define camera matrix (adjusted for a typical 640x480 image, you can change this)
focal_length = w  # Use the image width as a focal length approximation
center = (w // 2, h // 2)  # Optical center is assumed to be the image center

camera_matrix = np.array([[focal_length, 0, center[0]],  # fx, 0, cx
                          [0, focal_length, center[1]],  # 0, fy, cy
                          [0, 0, 1]], dtype=np.float32)  # Homogeneous coordinates

# Assumed distortion coefficients for fisheye (these are guesses, may need adjustment)
dist_coeffs = np.array([-0.2, 0.1, 0, 0], dtype=np.float32)

# Get the optimal new camera matrix (optional: improve output)
new_camera_matrix, roi = cv2.getOptimalNewCameraMatrix(camera_matrix, dist_coeffs, (w, h), 1, (w, h))

# Undistort the RGB image using fisheye
undistorted_bgr_image = cv2.fisheye.undistortImage(bgr_image, camera_matrix, dist_coeffs, Knew=new_camera_matrix)

# Crop the image using the ROI (this removes any black edges that may appear)
x, y, w, h = roi
undistorted_bgr_image = undistorted_bgr_image[y:y+h, x:x+w]

# If there was an alpha channel, merge it back into the undistorted image
if alpha_channel is not None:
    undistorted_image = cv2.merge([undistorted_bgr_image, alpha_channel[y:y+h, x:x+w]])
else:
    undistorted_image = undistorted_bgr_image

# Generate a unique filename for the undistorted image
base_name, extension = os.path.splitext(os.path.basename(image_path))
counter = 1
new_file_name = f"{base_name}_undistorted{extension}"

# Increment until we find a unique filename
while os.path.exists(new_file_name):
    counter += 1
    new_file_name = f"{base_name}_undistorted_{counter}{extension}"

# Save the undistorted image
cv2.imwrite(new_file_name, undistorted_image)
print(f"Undistorted image saved as: {new_file_name}")

