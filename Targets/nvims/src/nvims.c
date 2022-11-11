//
//  nvims.c
//  nvims
//
//  Created by Yevhenii Matviienko on 11.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#include <uv.h>
#include "nvims.h"

extern int nvim_main(int argc, char **argv);

uv_thread_t nvim_thread;

void nvim_thread_main(void *arg)
{
  char *nvim_arg = "nvim";
  nvim_main(1, &nvim_arg);
}

void nvims_start(void)
{
  uv_thread_create(&nvim_thread, nvim_thread_main, NULL);
}
