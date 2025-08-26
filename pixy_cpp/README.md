# Pixy2 Dual Camera Block Detection and JSON API

This C++ application interfaces with one or two Pixy2 cameras to detect colored objects (blocks), format the data as JSON, and send it to a backend server via HTTP POST requests.

## Features

- \*\*Dual Camera Support\*\*: Connects to and processes data from two Pixy2 cameras simultaneously

- \*\*JSON Output\*\*: Formats detected block data into structured JSON

- \*\*HTTP POST Integration\*\*: Sends data to a configurable backend endpoint

- \*\*Configurable Filtering\*\*: Filters blocks based on Y-coordinate ranges

- \*\*Coordinate Adjustment\*\*: Applies offsets to camera coordinates for spatial alignment

## Prerequisites

### Hardware

- One or two Pixy2 cameras connected via USB

- Internet connection for backend communication

### Software Dependencies

- libpixyusb2 (Pixy2 library)

- RapidJSON (for JSON processing)

- libcurl (for HTTP requests)

- C++11 compatible compiler

## Installation

1\. Install required libraries:

\`\`\`bash

# On Ubuntu/Debian

sudo apt-get install libcurl4-openssl-dev

# RapidJSON may need to be installed manually or via:

sudo apt-get install rapidjson-dev

\`\`\`

2\. Clone and build libpixyusb2:

\`\`\`bash

git clone https://github.com/charmedlabs/pixy2.git

cd pixy2/scripts

./build\_libpixyusb2.sh

sudo make install

\`\`\`

3\. Compile this application:

\`\`\`bash

g++ -o pixy\_detector main.cpp -lpixy2 -lcurl -std=c++11

\`\`\`

## Configuration

### Backend URL

Edit the \`backend\_url\` constant to point to your server:

\`\`\`cpp

const char\* backend\_url = "your-backend-url-here";

\`\`\`

### Camera Parameters

Adjust the filtering and offset parameters in the \`get\_blocks\_custom()\` calls:

\`\`\`cpp

// Parameters: camera, name, y-start, y-end, x-offset, y-offset

get\_blocks\_custom(pixy, "PC-CAMERA 1: ", 0, 207, 0, 0, jsonOutput);

\`\`\`

## Usage

Run the application:

\`\`\`bash

sudo ./pixy\_detector

\`\`\`

The application will:

1\. Initialize connection to available Pixy2 cameras

2\. Continuously detect colored blocks

3\. Format data as JSON

4\. Send to configured backend endpoint

5\. Run until terminated with Ctrl+C

## JSON Output Format

The application outputs JSON in the following format:

\`\`\`json

\[

{

"camera": "PC-CAMERA 1: ",

"num\_blocks": 2,

"blocks": \[

{

"index": 1,

"signature": 1,

"x": 150,

"y": 100,

"width": 30,

"height": 25

},

{

"index": 2,

"signature": 2,

"x": 280,

"y": 80,

"width": 25,

"height": 20

}

\]

}

\]

\`\`\`

## Troubleshooting

1\. \*\*Permission denied errors\*\*: Run with \`sudo\` to access USB devices

2\. \*\*Camera not detected\*\*: Check USB connections and ensure libpixyusb2 is installed

3\. \*\*HTTP errors\*\*: Verify backend URL and network connectivity

4\. \*\*No blocks detected\*\*: Adjust camera positioning and lighting conditions

## Security Note

The current implementation disables SSL certificate verification:

\`\`\`cpp

curl\_easy\_setopt(curl, CURLOPT\_SSL\_VERIFYPEER, 0L);

curl\_easy\_setopt(curl, CURLOPT\_SSL\_VERIFYHOST, 0L);

\`\`\`

For production use, implement proper certificate validation.

## License

This project uses libraries with their respective licenses:

- libpixyusb2 (Pixy2 SDK)

- RapidJSON (MIT License)

- libcurl (MIT License)

## Support

For issues related to:

- Pixy2 hardware: Contact Charmed Labs

- This software: Check the repository issues page
