#include <signal.h>
#include "libpixyusb2.h"
#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"

#include <curl/curl.h> // Include the libcurl header

Pixy2        pixy;
Pixy2        pixy2;
static bool  run_flag = true;


// Backend URL
//const char* backend_url = "http://127.0.0.1:5000/json";  // Replace with your backend URL
const char* backend_url = "https://nahid-sekander.duckdns.org/pixy/json";  // Replace with your backend URL

//const char* backend_url = "http://localhost:5000/json";  // Replace with your backend URL
//const char* backend_url = "http://192.168.2.18:5000/json";  // Replace with your backend URL



void handle_SIGINT(int unused)
{
  // On CTRL+C - abort! //
  run_flag = false;
}

void get_blocks(Pixy2& _pixy, const char* camera_name, rapidjson::Document& jsonOutput)
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

    //printf ("%s Detected %d block(s)\n", camera_name, _pixy.ccc.numBlocks);

    rapidjson::Value blocks(rapidjson::kArrayType);

    for (Block_Index = 0; Block_Index < _pixy.ccc.numBlocks; ++Block_Index)
    {
      rapidjson::Value block(rapidjson::kObjectType);
      block.AddMember("index", Block_Index + 1, jsonOutput.GetAllocator());
      block.AddMember("signature", _pixy.ccc.blocks[Block_Index].m_signature, jsonOutput.GetAllocator());
      block.AddMember("x", _pixy.ccc.blocks[Block_Index].m_x, jsonOutput.GetAllocator());
            
            /*
            // Check if camera_name is "CAMERA 2", then adjust y by adding the width of pixy2
            int adjusted_y = (strcmp(camera_name, "CAMERA 2:") == 0) 
                             //? _pixy.ccc.blocks[Block_Index].m_y + pixy2.getWidth()  // Add width of pixy2 to y for CAMERA 2
                             ? _pixy.ccc.blocks[Block_Index].m_y + 320  // Add width of pixy2 to y for CAMERA 2
                             : _pixy.ccc.blocks[Block_Index].m_y;  // Otherwise keep y as is
            */


      block.AddMember("y", _pixy.ccc.blocks[Block_Index].m_y, jsonOutput.GetAllocator());
      //block.AddMember("y", adjusted_y, jsonOutput.GetAllocator());
      block.AddMember("width", _pixy.ccc.blocks[Block_Index].m_width, jsonOutput.GetAllocator());
      block.AddMember("height", _pixy.ccc.blocks[Block_Index].m_height, jsonOutput.GetAllocator());

      blocks.PushBack(block, jsonOutput.GetAllocator());

    
      //printf ("  Block %d: ", Block_Index + 1);
      _pixy.ccc.blocks[Block_Index].print();
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
      printf("Data sent successfully to backend!\n");
    }

    // Cleanup
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
  } else {
    fprintf(stderr, "Failed to initialize curl.\n");
  }
}












int main()
{
  int Result;

  // Catch CTRL+C (SIGINT) signals //
  signal (SIGINT, handle_SIGINT);

  printf ("=============================================================\n");
  printf ("= PIXY2 Get Version =\n");
  printf ("=============================================================\n");

  printf ("Connecting to Pixy2...");

  // Initialize Pixy2 Connection //
  {
    Result = pixy.init();

    if (Result < 0)
    {
      printf ("Error\n");
      printf ("pixy.init() returned %d\n", Result);
      return Result;
    }
    
    Result = pixy2.init();

    if (Result < 0)
    {
      printf ("Error\n");
      printf ("pixy2.init() returned %d\n", Result);
      return Result;
    }

    printf ("Success\n");
  }

  // Get Pixy2 Version information //
  {
    Result = pixy.getVersion();

    if (Result < 0)
    {
      printf ("pixy.getVersion() returned %d\n", Result);
      return Result;
    }
    Result = pixy2.getVersion();
        
    if (Result < 0)
    {
      printf ("pixy2.getVersion() returned %d\n", Result);
      return Result;
    }

    pixy.version->print();
    pixy2.version->print();
  }

  // Set Pixy2 to color connected components program //
  pixy.changeProg("color_connected_components");
  while(1)
  {
    rapidjson::Document jsonOutput;
    jsonOutput.SetArray(); // Initialize as an array

    // Get blocks from both cameras
    get_blocks(pixy, "CAMERA 1: ", jsonOutput);
    get_blocks(pixy2, "CAMERA 2: ", jsonOutput);

    // Create a StringBuffer and Writer to output the JSON string
    rapidjson::StringBuffer buffer;
    rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
    jsonOutput.Accept(writer);

    printf("%s", buffer.GetString());  // Output the JSON string
    
    // Send the JSON data to the backend
    send_json_to_backend(jsonOutput);




    if (run_flag == false)
    {
      // Exit program loop //
      break;
    }
  }

  printf ("PIXY2 Get Blocks Demo Exit\n");
}

