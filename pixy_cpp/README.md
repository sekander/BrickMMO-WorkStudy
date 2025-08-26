Got it 👍 — you want the same style of structured **documentation / README** for your **Pixy2 Dual Camera Block Detection and JSON API** project, just like the GNOME Terminal guide. Here’s a clean version formatted like a proper README:

---

# Pixy2 Dual Camera Block Detection and JSON API

This C++ application interfaces with one or two **Pixy2 cameras** to detect coloured objects (blocks), format the data as **JSON**, and send it to a backend server via **HTTP POST** requests.

---

## ✨ Features

* **Dual Camera Support** – Connects to and processes data from two Pixy2 cameras simultaneously.
* **JSON Output** – Formats detected block data into structured JSON.
* **HTTP POST Integration** – Sends data to a configurable backend endpoint.
* **Configurable Filtering** – Filters blocks based on Y-coordinate ranges.
* **Coordinate Adjustment** – Applies offsets to camera coordinates for spatial alignment.

---

## 🔧 Prerequisites

### Hardware

* One or two Pixy2 cameras (USB connection).
* Internet connection for backend communication.

### Software Dependencies

* [`libpixyusb2`](https://github.com/charmedlabs/pixy2) (Pixy2 SDK).
* [RapidJSON](https://rapidjson.org/) (JSON processing).
* [libcurl](https://curl.se/libcurl/) (HTTP requests).
* A C++11 compatible compiler.

---

## ⚙️ Installation

### 1. Install required libraries

On **Ubuntu/Debian**:

```bash
sudo apt-get update
sudo apt-get install libcurl4-openssl-dev rapidjson-dev
```

If `rapidjson-dev` is not available, install it manually from source.

---

### 2. Clone and build `libpixyusb2`

```bash
git clone https://github.com/charmedlabs/pixy2.git
cd pixy2/scripts
./build_libpixyusb2.sh
sudo make install
```

---

### 3. Compile this application

```bash
g++ -o pixy_detector main.cpp -lpixy2 -lcurl -std=c++11
```

---

## ⚙️ Configuration

### Backend URL

Set your backend endpoint inside `main.cpp`:

```cpp
const char* backend_url = "your-backend-url-here";
```

### Camera Parameters

You can customise filtering and offsets in `get_blocks_custom()`:

```cpp
// Parameters: camera, name, y-start, y-end, x-offset, y-offset
get_blocks_custom(pixy, "PC-CAMERA 1: ", 0, 207, 0, 0, jsonOutput);
```

---

## ▶️ Usage

Run the program (requires root for USB access):

```bash
sudo ./pixy_detector
```

The program will:

1. Initialize connections to available Pixy2 cameras.
2. Continuously detect coloured blocks.
3. Format block data as JSON.
4. Send results to the configured backend endpoint.
5. Run until stopped with **Ctrl+C**.

---

## 📦 JSON Output Format

Example:

```json
[
  {
    "camera": "PC-CAMERA 1: ",
    "num_blocks": 2,
    "blocks": [
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
    ]
  }
]
```

---

## 🛠️ Troubleshooting

1. **Permission denied errors** – Run with `sudo` to access USB devices.
2. **Camera not detected** – Check USB connections and ensure `libpixyusb2` is installed.
3. **HTTP errors** – Verify backend URL and network connectivity.
4. **No blocks detected** – Adjust camera positioning and lighting.

---

## 🔒 Security Note

Currently SSL certificate verification is disabled for simplicity:

```cpp
curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);
```

➡️ For production, enable proper certificate validation.

---

## 📜 License

This project uses libraries with their respective licenses:

* `libpixyusb2` (Pixy2 SDK).
* `RapidJSON` (MIT License).
* `libcurl` (MIT License).

---

## 💬 Support

* **Pixy2 hardware issues** → [Charmed Labs](https://pixycam.com/).
* **This software** → Use the repository’s Issues page.

---

⚡Would you like me to also draft a **sample `main.cpp` skeleton** with the dual camera detection loop, JSON building, and cURL POST already wired up — so this README maps directly to runnable code?

