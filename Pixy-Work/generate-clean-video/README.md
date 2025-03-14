# Project README

## Overview
This project captures screenshots, corrects fisheye distortion, and compiles the processed images into a video.

## Components
### 1. `image_correction_test.py`
This script:
- Loads a fisheye PNG image.
- Splits the image into RGB and Alpha channels (if available).
- Defines a camera matrix and distortion coefficients.
- Undistorts the image using OpenCV.
- Saves the corrected image as `clean_image.png`, or with an incremented filename if it already exists.

### 2. `build_clean_video.py`
This script:
- Gathers all corrected images (`clean_image*.png`).
- Sorts them numerically.
- Compiles them into an `output.mp4` video at 8 FPS.
- Deletes the processed images after video creation.

### 3. `capture_script.sh`
This Bash script:
- Runs a loop to capture screenshots (using `scrot`).
- Passes each screenshot through `image_correction_test.py`.
- Deletes the original screenshot after processing.
- After 450 iterations (~5 minutes at 30 FPS), calls `build_clean_video.py` to generate the final video.

## Usage
1. Run the capture script:
   ```sh
   chmod +x capture_script.sh
   ./capture_script.sh
   ```
2. The final video will be saved as `output.mp4`.

## Dependencies
Ensure the following packages are installed:
- Python 3
- OpenCV (`pip install opencv-python numpy`)
- `scrot` (for capturing screenshots)

## Notes
- Modify the camera matrix and distortion coefficients in `image_correction_test.py` if necessary for better results.
- Adjust the FPS in `build_clean_video.py` as needed.
- The capture loop runs at 30 FPS; adjust `sleep 0.016667` in `capture_script.sh` to change it.


