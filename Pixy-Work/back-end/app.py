from flask import Flask, request, jsonify
import cv2
import numpy as np
import json

app = Flask(__name__)

@app.route('/')
def home():
    return 'Hello, Flask!'

@app.route('/json', methods=['POST'])
def handle_json():
    data = request.get_json()
    print("Received JSON:", data)

    
    if "signature" in data:
        try:
            print("Signature key exists:", data["signature"])
        
            sig = data['signature']
            j_x = data['x']
            j_y = data['y']
            j_w = data['width']
            j_h = data['height']

            #Camera Data
            w = 316
            h = 208
            centre = (w // 2, h //2)
            
            camera_matrix = np.array([[w, 0, centre[0]],  # fx, 0, cx
                                  [0, w, centre[1]],  # 0, fy, cy
                                  [0, 0, 1]], dtype=np.float32)  # Homogeneous coordinates
            # Assumed distortion coefficients for fisheye 
            dist_coeffs = np.array([-0.2, 0.1, 0, 0], dtype=np.float32)

            # Get the optimal new camera matrix 
            #new_camera_matrix, roi = cv2.getOptimalNewCameraMatrix(camera_matrix, dist_coeffs, (w, h), 1, (w, h))
            new_camera_matrix = cv2.getOptimalNewCameraMatrix(camera_matrix, dist_coeffs, (w, h), 1, (w, h))[0]

            point = np.array([[j_x, j_y]], dtype=np.float32)  # (1, 2) shape

            undistorted_points = cv2.undistortPoints(point, camera_matrix, dist_coeffs, P=new_camera_matrix)
            
            u_x = float(undistorted_points[0][0][0])
            u_y = float(undistorted_points[0][0][1])

            # Print the transformed data
            print("Original Camera Matrix:\n", camera_matrix)
            print("\nOptimized New Camera Matrix:\n", new_camera_matrix)
            print("Original Points Signature:", sig, "X:", j_x, "Y:", j_y, "Width:", j_w, "Height:", j_h)
            print("New Matrix applied to Original Points Signature:", sig, "X:", u_x, "Y:", u_y, "Width:", j_w, "Height:", j_h)

            return jsonify({
                "message": "PIXY JSON received successfully",
                "signature" : sig,
                "x": u_x,
                "y": u_y,
                "w": j_w,
                "h": j_h
            }), 200
        except json.JSONDecodeError as e:
            print("Failed to parse JSON:", e)
            return jsonify({
                "message": "ERROR : JSON ",
            }), 200
        except Exception as e:
            print("An unexpected error occurred:", e)
            return jsonify({
                "message": f"ERROR : JSON {str(e)}",
            }), 200
    else:
        print("Signature key is missing.")
        
        return jsonify({
            "message": "OTHER JSON received successfully",
        }), 200

    


if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)
