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

#include <signal.h>
#include "libpixyusb2.h"
#include <json/json.h>

Pixy2        pixy;
Pixy2        pixy2;
static bool  run_flag = true;


void handle_SIGINT(int unused)
{
  // On CTRL+C - abort! //

  run_flag = false;
}

//void  get_blocks()
//void  get_blocks(Pixy2& _pixy)
void  get_blocks(Pixy2& _pixy, const char* camera_name, Json::Value& jsonOutput)
{
  int  Block_Index;

  // Query Pixy for blocks //
  _pixy.ccc.getBlocks();

  // Were blocks detected? //
  if (_pixy.ccc.numBlocks)
  {
    // Blocks detected - print them! //
    Json::Value cameraData;
    cameraData["camera"] = camera_name;
    cameraData["num_blocks"] = _pixy.ccc.numBlocks;

    //printf ("CAM %p Detected %d block(s)\n", (void*)&_pixy, _pixy.ccc.numBlocks);
    printf ("%s Detected %d block(s)\n", camera_name, _pixy.ccc.numBlocks);

    for (Block_Index = 0; Block_Index < _pixy.ccc.numBlocks; ++Block_Index)
    {
        Json::Value block;
      block["index"] = Block_Index + 1;
      block["signature"] = _pixy.ccc.blocks[Block_Index].m_signature;
      block["x"] = _pixy.ccc.blocks[Block_Index].m_x;
      block["y"] = _pixy.ccc.blocks[Block_Index].m_y;
      block["width"] = _pixy.ccc.blocks[Block_Index].m_width;
      block["height"] = _pixy.ccc.blocks[Block_Index].m_height;

      cameraData["blocks"].append(block);
      printf ("  Block %d: ", Block_Index + 1);
      _pixy.ccc.blocks[Block_Index].print();
    }
    jsonOutput.append(cameraData);

  }
}

int main()
{
  int  Result;

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
    Json::Value jsonOutput;
    get_blocks(pixy, "CAMERA 1: ", jsonOutput);
    get_blocks(pixy2,"CAMERA 2: ", jsonOutput);

    Json::StreamWriterBuilder writer;
    std::string jsonString = Json::writeString(writer, jsonOutput);
    
    printf("%s", jsonString.c_str());

    if (run_flag == false)
    {
      // Exit program loop //
      break;
    }
  }

  printf ("PIXY2 Get Blocks Demo Exit\n");
}
