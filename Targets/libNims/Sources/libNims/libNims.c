
#include <uv.h>
#include "libNims.h"

extern int nvim_main(int argc, const char **argv);

static uv_thread_t nvim_thread;

void nvim_thread_entry(void* arg)
{
  const char *argv[2];
  argv[0] = "nvim";
  argv[1] = "-Es";
  
  nvim_main(2, argv);
}

void start_nvim(void)
{
  uv_thread_create(&nvim_thread, nvim_thread_entry, NULL);
}
