<?php

// Global variable to store processed data
$processed_data = [];


// Get the route from the query string (e.g., ?route=json)
$route = isset($_GET['route']) ? $_GET['route'] : null;

// Home route
if ($_SERVER['REQUEST_URI'] == '/') {
    echo "Hello, PHP!" . " " . $_SERVER['REQUEST_URI'];
    exit;
}

// Route to handle JSON input
if ($route == 'json' && $_SERVER['REQUEST_METHOD'] == 'POST') {
//if ($_SERVER['REQUEST_URI'] == '/json' && $_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    if (isset($data['signature'])) {
        try {
            $sig = $data['signature'];
            $j_x = $data['x'];
            $j_y = $data['y'];
            $j_w = $data['width'];
            $j_h = $data['height'];

            // Camera Data
            $w = 316;
            $h = 208;
            $centre = ['x' => $w / 2, 'y' => $h / 2];

            // Camera Matrix (3x3 matrix)
            $camera_matrix = [
                [$w, 0, $centre['x']], 
                [0, $w, $centre['y']], 
                [0, 0, 1]
            ];

            // Distortion Coefficients (Assumed for fisheye)
            $dist_coeffs = [-0.2, 0.1, 0, 0];

            // Simulate undistorting the points manually (in place of OpenCV)
            $undistorted_points = undistort_points($j_x, $j_y, $camera_matrix, $dist_coeffs);

            $u_x = $undistorted_points[0];
            $u_y = $undistorted_points[1];

            // Update global processed data
            $GLOBALS['processed_data'] = [
                'signature' => $sig,
                'x' => $u_x,
                'y' => $u_y,
                'w' => $j_w,
                'h' => $j_h
            ];

            $result = [
                'message' => 'PIXY JSON received successfully',
                'signature' => $sig,
                'x' => $u_x,
                'y' => $u_y,
                'w' => $j_w,
                'h' => $j_h
            ];
            header('Content-Type: application/json');
            echo json_encode($result);
        } catch (Exception $e) {
            header('Content-Type: application/json');
            echo json_encode(['message' => 'ERROR: ' . $e->getMessage()]);
        }
    } else {
        header('Content-Type: application/json');
        echo json_encode(['message' => 'OTHER JSON received successfully']);
    }
    exit;
}

// Route to get processed JSON data
if ($route == 'get_json' && $_SERVER['REQUEST_METHOD'] == 'GET') {
//if ($_SERVER['REQUEST_URI'] == '/get_json' && $_SERVER['REQUEST_METHOD'] == 'GET') {
    if (!empty($GLOBALS['processed_data'])) {
        header('Content-Type: application/json');
        echo json_encode($GLOBALS['processed_data']);
    } else {
        header('Content-Type: application/json');
        echo json_encode(['message' => 'No data available']);
    }
    exit;
}

// Route to serve the MP4 video
if ($_SERVER['REQUEST_URI'] == '/video' && $_SERVER['REQUEST_METHOD'] == 'GET') {
    $video_path = __DIR__ . '/output.mp4';
    if (file_exists($video_path)) {
        header('Content-Type: video/mp4');
        header('Content-Disposition: inline; filename="output.mp4"');
        readfile($video_path);
    } else {
        header('Content-Type: application/json');
        echo json_encode(['message' => 'Video not found']);
    }
    exit;
}

// Simulate undistorting points manually
function undistort_points($x, $y, $camera_matrix, $dist_coeffs) {
    // For simplicity, this is just an approximation of the undistortion process
    // In reality, you would need to implement the actual math for undistortion here
    $undistorted_x = $x + 5;  // Fake undistortion calculation
    $undistorted_y = $y + 5;  // Fake undistortion calculation
    return [$undistorted_x, $undistorted_y];
}

?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fetch and Print JSON Data</title>

    <style>
        canvas {
            border: 1px solid black;
        }
    </style>
    <script>
        // Function to fetch processed JSON data from Flask backend
        function fetchProcessedJsonData() {
            fetch('https://nahid-sekander.duckdns.org/projects/php/pixy/get_json', {
            //fetch('http://192.168.2.18:5000/get_json', {
                method: 'GET',
            })
            .then(response => response.json())
            .then(data => {
                console.log('Processed JSON Data:', data);
                displayJsonData(data); // Function to display data on the frontend
                //drawRedSquare(data.blocks[0].x, data.blocks[0].y);
                //console.log(data.blocks[0].x)
                //console.log(data.blocks[0].y);
                drawBlocks(data[0].blocks);

            })
            .catch(error => {
                console.error('Error fetching data:', error);
            });
        }

        // Function to display the fetched JSON data on the page
        function displayJsonData(data) {
            const dataContainer = document.getElementById('jsonData');
            dataContainer.innerHTML = JSON.stringify(data, null, 2); // Prettify the JSON
        }

        // Function to draw blocks on the canvas
        function drawBlocks(blocks) {
            const canvas = document.getElementById('canvas');
            const ctx = canvas.getContext('2d');
            //console.log(blocks['signature']);
            ctx.clearRect(0, 0, canvas.width, canvas.height); // Clear the canvas before drawing

            let detectedColour;

            blocks.forEach(block => {
                console.log(block.signature); // Logs 1 and 2
                if (block.signature == 1)
                    ctx.fillStyle =  'red'; // Set the fill color to red
                else if (block.signature == 2)
                    ctx.fillStyle =  'orange'; // Set the fill color to red
                else if (block.signature == 3)
                    ctx.fillStyle =  'blue'; // Set the fill color to red
                else if (block.signature == 4)
                    ctx.fillStyle =  'green'; // Set the fill color to red
                ctx.fillStyle = detectedColour; // Set the fill color to red
                ctx.fillRect(block.x, block.y, block.width, block.height); // Draw each block
            });
        }

        // Call the fetch function every 1000 milliseconds (1 second)
        //setInterval(fetchProcessedJsonData, 1000);
        setInterval(fetchProcessedJsonData, 1000);

    </script>
</head>
<body>
    <!-- <?php phpinfo(); ?> -->
    <h1>Processed JSON Data</h1>

    <!-- Container to display the fetched JSON data -->
    <pre id="jsonData">Loading...</pre>

    <!-- Canvas to render the data -->
    <canvas id="canvas" width="640" height="480"></canvas>
</body>
</html>

