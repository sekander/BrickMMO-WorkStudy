#!/bin/bash

echo hi

echo "Starting 5-minute capture loop at 30 fps"

for ((i=1; i<=450; i++))
do
    scrot -a 8,105,650,425 snap.png
    python3 image_correction_test.py snap.png
    rm snap.png
    sleep 0.016667  # 1 / 30 fps = 0.0333 seconds
done

python3 build_clean_video.py
rm clean_image*.png
echo "Completed"

