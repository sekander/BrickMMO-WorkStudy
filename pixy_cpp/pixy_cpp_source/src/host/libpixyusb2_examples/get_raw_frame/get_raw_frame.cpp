//
// begin license header
//
// This file is part of Pixy CMUcam5 or "Pixy" for short
//
// All Pixy source code is provided under the terms of the
// GNU General Public License v2 (http://www.gnu.org/licenses/gpl-2.0.html).
// Those wishing to use Pixy source code, software and/or
// technologies under different licensing terms should contact us at
// cmucam@cs.cmu.edu. Such licensing terms are available for
// all portions of the Pixy codebase presented here.
//
// end license header
//

#include "libpixyusb2.h"
#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"

#include <curl/curl.h> // Include the libcurl header


Pixy2        pixy;
//Pixy2        pixy2;
static bool  run_flag = true;


// Backend URL
const char* backend_url = "http://127.0.0.1:5000/json";  // Replace with your backend URL
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
            
            
            // Check if camera_name is "CAMERA 2", then adjust y by adding the width of pixy2
            int adjusted_y = (strcmp(camera_name, "CAMERA 2:") == 0) 
                             //? _pixy.ccc.blocks[Block_Index].m_y + pixy2.getWidth()  // Add width of pixy2 to y for CAMERA 2
                             ? _pixy.ccc.blocks[Block_Index].m_y + 320  // Add width of pixy2 to y for CAMERA 2
                             : _pixy.ccc.blocks[Block_Index].m_y;  // Otherwise keep y as is


      //block.AddMember("y", _pixy.ccc.blocks[Block_Index].m_y, jsonOutput.GetAllocator());
      block.AddMember("y", adjusted_y, jsonOutput.GetAllocator());
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


//Pixy2        pixy;


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

int demosaic(uint16_t width, uint16_t height, const uint8_t *bayerImage, uint32_t *image)
{
  uint32_t x, y, xx, yy, r, g, b;
  uint8_t *pixel0, *pixel;
    printf("Height : %d", height);
  
  for (y=0; y<height; y++)
  {


        if(y > 180)
            return;
        printf("Y: %d", y);
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


int main()
{
  int  Result;
  uint8_t *bayerFrame;
  uint32_t rgbFrame[PIXY2_RAW_FRAME_WIDTH*PIXY2_RAW_FRAME_HEIGHT];
  
  printf ("=============================================================\n");
  printf ("= PIXY2 Get Raw Frame Example                               =\n");
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
    /*
    Result = pixy2.init();

    if (Result < 0)
    {
      printf ("Error\n");
      printf ("pixy2.init() returned %d\n", Result);
      return Result;
    }

        */

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

        /*
    Result = pixy2.getVersion();

    if (Result < 0)
    {
      printf ("pixy2.getVersion() returned %d\n", Result);
      return Result;
    }
        */

    pixy.version->print();
    //pixy2.version->print();


    //pixy.version->print();
  }

  // need to call stop() befroe calling getRawFrame().
  // Note, you can call getRawFrame multiple times after calling stop().
  // That is, you don't need to call stop() each time.
  pixy.m_link.stop();

  // grab raw frame, BGGR Bayer format, 1 byte per pixel
  pixy.m_link.getRawFrame(&bayerFrame);
  // convert Bayer frame to RGB frame
    demosaic(PIXY2_RAW_FRAME_WIDTH, PIXY2_RAW_FRAME_HEIGHT, bayerFrame, rgbFrame);





    //printf("Working");
  // write frame to PPM file for verification
  Result = writePPM(PIXY2_RAW_FRAME_WIDTH, PIXY2_RAW_FRAME_HEIGHT, rgbFrame, "out");
  if (Result==0)
    printf("Write frame to out.ppm\n");
  
  // Call resume() to resume the current program, otherwise Pixy will be left
  // in "paused" state.  
  pixy.m_link.resume();
}
