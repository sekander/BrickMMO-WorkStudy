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
pixy2 = Pixy2(port=4, i2c_address=0x54)


# Create an I2C device object
pixy = I2CDevice(Port.S1, 0x54)


# Get version
version = pixy2.get_version()
print('Hardware: ', version.hardware)
print('Firmware: ', version.firmware)

# Get frame resolution
resolution = pixy2.get_resolution()
print('Frame width:  ', resolution.width)
print('Frame height: ', resolution.height)




# Turn upper leds on for 2 seconds, then turn off
pixy2.set_lamp(1, 0)
wait(1000)
pixy2.set_lamp(0, 0)

# Initialize EV3 Brick
ev3 = EV3Brick()

motor = Motor(Port.A)  # Motor on Port A
#motor = Motor('outA')  # Motor on Port A
if(motor):
    print("Port A motor is functioning")
else:
    print("Port A motor is not connected")

touchSensor = False 
#sensor = TouchSensor('in4')  # Touch sensor on Port 1
sensor = TouchSensor(Port.S1)  # Touch sensor on Port 1
if(sensor):
    print("Port 1 sensor is functioning ")
    touchSensor = True
else:
    print("Port 1 sensor is not connected ")
    touchSensor = False
# Spin motor at 500°/s
# motor.dc(100)

# motor_speed = touchSenor ? 100 : 0
motor_speed = 100 if touchSensor else 0

motor.dc(motor_speed)

# The URL of the API endpoint
url = "http://192.168.2.18:5000/json"


# Convert data to JSON
headers = {'Content-Type': 'application/json'}




##Functions
def read_pixy_data():
     # Request the blocks detected by Pixy2 (get at most 1 block)
        nr_blocks, blocks = pixy2.get_blocks(1, 1)

        # Check if at least one block is detected
        if nr_blocks >= 1:
            # Extract data from the first block
            sig = blocks[0].sig
            x = blocks[0].x_center
            y = blocks[0].y_center
            w = blocks[0].width
            h = blocks[0].height

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


