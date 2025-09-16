#include <signal.h>
#include "libpixyusb2.h"
#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"
#include <chrono>
#include <thread>
#include <vector>

#include <curl/curl.h> // Include the libcurl header

Pixy2 pixy, pixy2, pixy3, pixy4;
static bool run_flag = true;

// Backend URL
const char* backend_url = "https://nahid-sekander.duckdns.org/pixy/json_0"; // Replace with your backend URL

void handle_SIGINT(int unused)
{
    // On CTRL+C - abort! //
    run_flag = false;
}

void get_blocks_custom(Pixy2& _pixy, const char* camera_name, int start, int end, int offsetX, int offsetY, rapidjson::Document& jsonOutput)
{
    int Block_Index;

    // Query Pixy for blocks //
    _pixy.ccc.getBlocks();

    // Were blocks detected? //
    if (_pixy.ccc.numBlocks)
    {
        // Blocks detected - print them! //
        rapidjson::Value cameraData(rapidjson::kObjectType);
        cameraData.AddMember("camera", rapidjson::Value(camera_name, jsonOutput.GetAllocator()), jsonOutput.GetAllocator());
        cameraData.AddMember("num_blocks", _pixy.ccc.numBlocks, jsonOutput.GetAllocator());

        rapidjson::Value blocks(rapidjson::kArrayType);

        for (Block_Index = 0; Block_Index < _pixy.ccc.numBlocks; ++Block_Index)
        {
            if(_pixy.ccc.blocks[Block_Index].m_y > start && _pixy.ccc.blocks[Block_Index].m_y < end)
            {
                rapidjson::Value block(rapidjson::kObjectType);
                block.AddMember("index", Block_Index + 1, jsonOutput.GetAllocator());
                block.AddMember("signature", _pixy.ccc.blocks[Block_Index].m_signature, jsonOutput.GetAllocator());
                auto check_camera_type = std::string(camera_name);
                if(check_camera_type.find("CAMERA 2") != std::string::npos)
                {
                    block.AddMember("x", _pixy.ccc.blocks[Block_Index].m_x + 315, jsonOutput.GetAllocator());
                }
                else {
                    block.AddMember("x", _pixy.ccc.blocks[Block_Index].m_x + offsetX, jsonOutput.GetAllocator());
                }

                block.AddMember("y", _pixy.ccc.blocks[Block_Index].m_y + offsetY, jsonOutput.GetAllocator());
                block.AddMember("width", _pixy.ccc.blocks[Block_Index].m_width, jsonOutput.GetAllocator());
                block.AddMember("height", _pixy.ccc.blocks[Block_Index].m_height, jsonOutput.GetAllocator());

                blocks.PushBack(block, jsonOutput.GetAllocator());

                // _pixy.ccc.blocks[Block_Index].print(); // Removed this print
            }
            else
                return;
        }

        cameraData.AddMember("blocks", blocks, jsonOutput.GetAllocator());
        jsonOutput.PushBack(cameraData, jsonOutput.GetAllocator());
    }
}

// Function to send the JSON data to the backend via HTTP POST
void send_json_to_backend(const rapidjson::Document& jsonData)
{
    // Initialize libcurl
    CURL* curl = curl_easy_init();
    if (curl) {
        // Set up the URL for the backend
        curl_easy_setopt(curl, CURLOPT_URL, backend_url);
        
        // ----DANGER DISBALE CERTIFICATE VERIFICATION
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);
        // ----DANGER DISBALE CERTIFICATE VERIFICATION

        // Set up the headers for JSON content type
        struct curl_slist* headers = NULL;
        headers = curl_slist_append(headers, "Content-Type: application/json");

        // Convert the JSON document to a string
        rapidjson::StringBuffer buffer;
        rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
        jsonData.Accept(writer);

        // Send the JSON string as a POST request
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, buffer.GetString());

        // Perform the HTTP POST request
        CURLcode res = curl_easy_perform(curl);
        if (res != CURLE_OK) {
            fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
        } else {
            // printf("\nData sent successfully to backend!\n"); // Removed this print
        }

        // Cleanup
        curl_slist_free_all(headers);
        curl_easy_cleanup(curl);
    } else {
        fprintf(stderr, "Failed to initialize curl.\n");
    }
}

bool send_frame_to_backend(const std::string& ppm_data) {
    CURL *curl = curl_easy_init();
    if (!curl) return false;

    struct curl_slist *headers = nullptr;
    headers = curl_slist_append(headers, "Content-Type: image/x-portable-pixmap");

    curl_easy_setopt(curl, CURLOPT_URL, "https://nahid-sekander.duckdns.org/pixy/upload");
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, ppm_data.c_str());
    curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, ppm_data.size());

    CURLcode res = curl_easy_perform(curl);
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);

    return res == CURLE_OK;
}

int writePPM(uint16_t width, uint16_t height, uint32_t *image, const char *filename)
{
    int i, j;
    char fn[32];

    sprintf(fn, "%s.ppm", filename);
    FILE *fp = fopen(fn, "wb");
    if (fp==NULL)
        return -1;
    fprintf(fp, "P6\n%d %d\n255\n", width, height);
    for (j=0; j<height; j++)
    {
        for (i=0; i<width; i++)
            fwrite((char *)(image + j*width + i), 1, 3, fp);
    }
    fclose(fp);
    return 0;
}

void demosaic(uint16_t width, uint16_t height, const uint8_t *bayerImage, uint32_t *image)
{
    uint32_t x, y, xx, yy, r, g, b;
    uint8_t *pixel0, *pixel;
    // printf("Height : %d", height); // Removed this print
    
    for (y=0; y<height; y++)
    {
        if(y > 180)
            return;
        // printf("Y: %d", y); // Removed this print
        
        yy = y;
        if (yy==0)
            yy++;
        else if (yy==height-1)
            yy--;
        
        pixel0 = (uint8_t *)bayerImage + yy*width;

        for (x=0; x<width; x++, image++)
        {
            xx = x;
            if (xx==0)
                xx++;
            else if (xx==width-1)
                xx--;
            pixel = pixel0 + xx;
            if (yy&1)
            {
                if (xx&1)
                {
                    r = *pixel;
                    g = (*(pixel-1)+*(pixel+1)+*(pixel+width)+*(pixel-width))>>2;
                    b = (*(pixel-width-1)+*(pixel-width+1)+*(pixel+width-1)+*(pixel+width+1))>>2;
                }
                else
                {
                    r = (*(pixel-1)+*(pixel+1))>>1;
                    g = *pixel;
                    b = (*(pixel-width)+*(pixel+width))>>1;
                }
            }
            else
            {
                if (xx&1)
                {
                    r = (*(pixel-width)+*(pixel+width))>>1;
                    g = *pixel;
                    b = (*(pixel-1)+*(pixel+1))>>1;
                }
                else
                {
                    r = (*(pixel-width-1)+*(pixel-width+1)+*(pixel+width-1)+*(pixel+width+1))>>2;
                    g = (*(pixel-1)+*(pixel+1)+*(pixel+width)+*(pixel-width))>>2;
                    b = *pixel;
                }
            }
            *image = (b<<16) | (g<<8) | r;
        }
    }
}

void saveFrame(Pixy2 &_pixy, const char cameraName[8], int &Result)
{
    uint8_t *bayerFrame = nullptr;
    uint32_t rgbFrame[PIXY2_RAW_FRAME_WIDTH * PIXY2_RAW_FRAME_HEIGHT]; // Thread-local RGB buffer
    // need to call stop() befroe calling getRawFrame().
    // Note, you can call getRawFrame multiple times after calling stop().
    // That is, you don't need to call stop() each time.
    _pixy.m_link.stop();
    // grab raw frame, BGGR Bayer format, 1 byte per pixel
    _pixy.m_link.getRawFrame(&bayerFrame);

     // Safety check: avoid segmentation fault if frame not available
    if (!bayerFrame)
    {
        fprintf(stderr, "Error: Null Bayer frame received from %s\n", cameraName);
        Result = -1;
        _pixy.m_link.resume(); // Always resume Pixy even on failure
        return;
    }

    // convert Bayer frame to RGB frame
    demosaic(PIXY2_RAW_FRAME_WIDTH, PIXY2_RAW_FRAME_HEIGHT, bayerFrame, rgbFrame);
    static int frameCounter = 0; // Counter to keep track of frame numbers
    char filename[64]; // Buffer to hold the filename

    // Create the filename with the counter appended
    sprintf(filename, "frames/%s_frame_%d", cameraName, frameCounter++);

    // Write frame to PPM file for verification
    Result = writePPM(PIXY2_RAW_FRAME_WIDTH, PIXY2_RAW_FRAME_HEIGHT, rgbFrame, filename);
    if (Result == 0)
        // printf("Frame saved to %s.ppm\n", filename); // Removed this print

    // Call resume() to resume the current program, otherwise Pixy will be left
    // in "paused" state.
    _pixy.m_link.resume();

    std::this_thread::sleep_for(std::chrono::milliseconds(100));
}

void transmitData(rapidjson::Document& jsonOutput, std::vector<bool>activatedCameras)
{
    jsonOutput.SetArray(); // Initialize as an array
    {
        get_blocks_custom(pixy, "PC-CAMERA 1: ", 0, 207, 0, 0, jsonOutput);
    }
    {
        get_blocks_custom(pixy2, "PC-CAMERA 2: ", 0, 207, 0, 0, jsonOutput);
    }
    rapidjson::StringBuffer buffer;
    rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
    jsonOutput.Accept(writer);

    if(jsonOutput.IsNull() || jsonOutput.Empty())
    {
        // printf("\nEmpty did not send to backend\n"); // Removed this print
        // printf("%s\n", buffer.GetString()); // Removed this print
    }else{
        // Send the JSON data to the backend
        send_json_to_backend(jsonOutput);
    }
}

int main()
{
    int Result;
    rapidjson::Document jsonOutput;
    //uint8_t *bayerFrame;
    //uint32_t rgbFrame[PIXY2_RAW_FRAME_WIDTH*PIXY2_RAW_FRAME_HEIGHT];

    std::vector<bool> activeCameras(4, false); // Vector to track active cameras

    // Catch CTRL+C (SIGINT) signals //
    signal (SIGINT, handle_SIGINT);

    // printf ("=============================================================\n"); // Removed this print
    // printf ("= PIXY2 Get Version =\n"); // Removed this print
    // printf ("=============================================================\n"); // Removed this print

    // printf ("Connecting to Pixy2..."); // Removed this print

    // Initialize Pixy2 Connection //
    {
        Result = pixy.init();

        if (Result < 0)
        {
            // printf ("Error Pixy 1 Failed to intiate \n"); // Removed this print
            // printf ("pixy.init() returned %d\n", Result); // Removed this print
        }
        else
        {
            activeCameras[0] = true; // Mark CAMERA 1 as active
            pixy.version->print();
            //pixy.setLamp(1, 1);
            // printf ("Success Pixy 1\n"); // Removed this print
        }
        
        Result = pixy2.init();

        if (Result < 0)
        {
            // printf ("Error Pixy 2 Failed to intiate \n"); // Removed this print
            // printf ("pixy2.init() returned %d\n", Result); // Removed this print
        }
        else
        {
            activeCameras[1] = true; // Mark CAMERA 1 as active
            pixy2.version->print();
            //pixy2.setLamp(1, 1);
            // printf ("Success Pixy 2\n"); // Removed this print
        }

        // printf ("All camera's intiated\n"); // Removed this print
    }

    // Get Pixy2 Version information //
    if(activeCameras[0])
    {
        // printf ("=============================================================\n"); // Removed this print
        // printf ("= CAMERA 1: Get Version =\n"); // Removed this print
        // printf ("=============================================================\n"); // Removed this print

        Result = pixy.getVersion();

        if (Result < 0)
        {
            // printf ("pixy.getVersion() returned %d\n", Result); // Removed this print
            return Result;
        }
        pixy.version->print();
        // Set Pixy2 to color connected components program //
        pixy.changeProg("color_connected_components");
    }

    if(activeCameras[1])
    {
        // printf ("=============================================================\n"); // Removed this print
        // printf ("= CAMERA 2: Get Version =\n"); // Removed this print
        // printf ("=============================================================\n"); // Removed this print

        Result = pixy2.getVersion();

        if (Result < 0)
        {
            // printf ("pixy.getVersion() returned %d\n", Result); // Removed this print
            return Result;
        }
        pixy2.version->print();
        pixy2.changeProg("color_connected_components");
    }
    if(activeCameras[2])
    {
        // printf ("=============================================================\n"); // Removed this print
        // printf ("= CAMERA 3: Get Version =\n"); // Removed this print
        // printf ("=============================================================\n"); // Removed this print

        Result = pixy3.getVersion();

        if (Result < 0)
        {
            // printf ("pixy.getVersion() returned %d\n", Result); // Removed this print
            return Result;
        }
        pixy3.version->print();
    }
    if(activeCameras[3])
    {
        // printf ("=============================================================\n"); // Removed this print
        // printf ("= CAMERA 4: Get Version =\n"); // Removed this print
        // printf ("=============================================================\n"); // Removed this print

        Result = pixy4.getVersion();

        if (Result < 0)
        {
            // printf ("pixy.getVersion() returned %d\n", Result); // Removed this print
            return Result;
        }
        pixy4.version->print();
    }
    
    while(1)
    {
        // Launch transmitData in a separate thread
        static std::thread transmitThread([&]() {
            while (run_flag) {
                // printf("\n\n=====================\n"); // Removed this print
                // printf("= Get Blocks Demo =\n"); // Removed this print
                // printf("\n\n=====================\n"); // Removed this print
                transmitData(jsonOutput, activeCameras);
                std::this_thread::sleep_for(std::chrono::milliseconds(100)); // Add a small delay to avoid excessive CPU usage
            }
        });

        // Launch saveFrame in a separate thread
        static std::thread saveFrameThread([&]() {
            while (run_flag) {
                // printf("\n\n=====================\n"); // Removed this print
                // printf("= Get Raw Frame Demo =\n"); // Removed this print
                // printf("\n\n=====================\n"); // Removed this print
                //saveFrame(pixy, "Camera 1", bayerFrame, rgbFrame, Result);
                
                saveFrame(pixy, "Camera 1", Result);
                std::this_thread::sleep_for(std::chrono::milliseconds(500)); // Add a small delay to avoid excessive CPU usage
            }
        });
        // Launch saveFrame in a separate thread
        static std::thread saveSecondFrameThread([&]() {
            while (run_flag) {
                // printf("\n\n=====================\n"); // Removed this print
                // printf("= Get Raw Frame Demo =\n"); // Removed this print
                // printf("\n\n=====================\n"); // Removed this print
                //saveFrame(pixy2, "Camera 2", bayerFrame, rgbFrame, Result);
                saveFrame(pixy2, "Camera 2", Result);
                std::this_thread::sleep_for(std::chrono::milliseconds(500)); // Add a small delay to avoid excessive CPU usage
            }
        });

        // Ensure threads are only started once
        if (!transmitThread.joinable() 
                || !saveFrameThread.joinable() 
                || !saveSecondFrameThread.joinable()
                ) 
        {
            saveFrameThread.detach();
            saveSecondFrameThread.detach();
            transmitThread.detach();
        }
        if (run_flag == false)
        {
            // Exit program loop //
            break;
        }
    }

    jsonOutput.SetNull(); // Clear the JSON document
    send_json_to_backend(jsonOutput);
    // printf ("PIXY2 Get Blocks Demo Exit\n"); // Removed this print
}

