import cv2
import os

# Get list of images and sort them numerically by extracting the number from the filenames
images = [f for f in os.listdir() if f.endswith('.png')]

# Sort the images by extracting the number, defaulting to 0 if no number is found
images.sort(key=lambda x: int(''.join(filter(str.isdigit, x.split('clean_image')[-1]))) if any(c.isdigit() for c in x.split('clean_image')[-1]) else 0)

# Read the first image to get the dimensions
first_image = cv2.imread(images[0])
height, width, _ = first_image.shape

# Define the codec and create a VideoWriter object
fourcc = cv2.VideoWriter_fourcc(*'mp4v')  # or 'XVID' for .avi files
#fps = 30
fps = 8 
video_out = cv2.VideoWriter('output.mp4', fourcc, fps, (width, height))

# Loop through images and write them to the video
for image in images:
    img = cv2.imread(image)
    video_out.write(img)

video_out.release()
print("Video created successfully!")

