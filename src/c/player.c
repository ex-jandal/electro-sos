#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio/miniaudio.h"

#include <unistd.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
  ma_result result;
  ma_engine engine;

  // Initialize the high-level engine
  result = ma_engine_init(NULL, &engine);
  if (result != MA_SUCCESS) {
      return -1;
  }

  // Play a sound file
  ma_engine_play_sound(&engine, argv[1], NULL);

  sleep(atoi(argv[2]));
  ma_engine_uninit(&engine);
  return EXIT_SUCCESS;
}
