#!/usr/bin/env pybricks-micropython
import json
import urequests 
import time
from pybricks.hubs import EV3Brick
from pybricks.ev3devices import (Motor, TouchSensor, ColorSensor,
                                 InfraredSensor, UltrasonicSensor, GyroSensor)
from pybricks.parameters import Port, Stop, Direction, Button, Color
from pybricks.tools import wait, StopWatch, DataLog
from pybricks.robotics import DriveBase
from pybricks.media.ev3dev import SoundFile, ImageFile
from pybricks.iodevices import I2CDevice

# Import the Pixy2 library
from pixycamev3.pixy2 import Pixy2

# Initialize the EV3 Brick
ev3 = EV3Brick()

# Set volume to 100% and make a beep to signify program has started
ev3.speaker.set_volume(100)
ev3.speaker.beep()

# Turn off the light
ev3.light.off()

# Connec the Pixy2 to port 1
pixy2_cam1 = Pixy2(port=1, i2c_address=0x54)
pixy2_cam2 = Pixy2(port=4, i2c_address=0x54)

# Get version
version = pixy2_cam1.get_version()
print('Hardware: ', version.hardware)
print('Firmware: ', version.firmware)

# Get frame resolution
resolution = pixy2_cam1.get_resolution()
print('Frame width:  ', resolution.width)
print('Frame height: ', resolution.height)

# Turn upper leds on for 2 seconds, then turn off
pixy2_cam1.set_lamp(1, 0)
wait(1000)
pixy2_cam1.set_lamp(0, 0)

version = pixy2_cam2.get_version()
print('Hardware: ', version.hardware)
print('Firmware: ', version.firmware)

resolution = pixy2_cam2.get_resolution()
print('Frame width:  ', resolution.width)
print('Frame height: ', resolution.height)

# Turn upper leds on for 2 seconds, then turn off
pixy2_cam2.set_lamp(1, 0)
wait(1000)
pixy2_cam2.set_lamp(0, 0)


# Initialize EV3 Brick
ev3 = EV3Brick()

# The URL of the API endpoint
url = "http://192.168.2.18:5000/json"

# Convert data to JSON
headers = {'Content-Type': 'application/json'}




##Functions
def read_pixy_data():
     # Request the blocks detected by Pixy2 (get at most 1 block)
        #nr_blocks, blocks = pixy2_cam1.get_blocks(1, 1)
        nr_blocks1, blocks1 = pixy2_cam1.get_blocks(1, 1)
        nr_blocks2, blocks2 = pixy2_cam2.get_blocks(1, 1)

        # Check if at least one block is detected
        #if nr_blocks >= 1:
        if nr_blocks1 >= 1:
            # Extract data from the first block
            sig = blocks1[0].sig
            x = blocks1[0].x_center
            y = blocks1[0].y_center
            w = blocks1[0].width
            h = blocks1[0].height

            # Print extracted data (can be removed if not needed)
            print("Signature:", sig, "X:", x, "Y:", y, "Width:", w, "Height:", h)

            # Create a dictionary with the extracted data
            block_data = {
                'signature': sig,
                'x': x,
                'y': y,
                'width': w,
                'height': h
            }

            # Convert the dictionary to a JSON-formatted string
            #return json.dumps(block_data)
            return (block_data)
        elif nr_blocks2 >= 1:
            # Extract data from the first block
            sig = blocks2[0].sig
            x = blocks1[0].x_center
            y = blocks1[0].y_center + resolution.width
            w = blocks1[0].width
            h = blocks1[0].height

            # Print extracted data (can be removed if not needed)
            print("Signature:", sig, "X:", x, "Y:", y, "Width:", w, "Height:", h)

            # Create a dictionary with the extracted data
            block_data = {
                'signature': sig,
                'x': x,
                'y': y,
                'width': w,
                'height': h
            }

            # Convert the dictionary to a JSON-formatted string
            #return json.dumps(block_data)
            return (block_data)

        else:
            # No blocks detected, return error in JSON
            return json.dumps({"error": "No blocks detected"})


while True:

    # get_raw_color_data()
    # nr_blocks, blocks = pixy2.get_blocks(1, 1)
    data = read_pixy_data()
    print(data)

    # Send the POST request with the JSON data
    response = urequests.post(url, json=data)

    # Check if the response status code is 200 (OK)
    if response.status_code == 200:
        print("Response received:", response.text)  # Print the response content
    else:
        print("Error:", response.status_code)  # Print the error code

    time.sleep(2)
    # Close the response to free up memory
    response.close()


    # Check for center button events
    if Button.CENTER in ev3.buttons.pressed():
        ev3.light.off()
        break

    wait(500)

# Use the speech tool to signify the program has finished
ev3.speaker.say("Program complete")


