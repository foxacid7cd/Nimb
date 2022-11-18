//
//  nvims.c
//  nvims
//
//  Created by Yevhenii Matviienko on 11.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#include <uv.h>
#include <nvim/api/vim.h>
#include "nvims.h"

extern int nvim_main(int argc, char **argv);

nvims_ui_t nvims_ui;
uv_thread_t nvim_thread;

void nvim_thread_main(void *arg)
{
  char *nvim_arg = "nvim";
  nvim_main(1, &nvim_arg);
}

void nvims_start(nvims_ui_t arg)
{
  nvims_ui = arg;
  uv_thread_create(&nvim_thread, nvim_thread_main, NULL);
}

int64_t nvims_input(nvim_string_t keys)
{
  String nvim_keys = { .data = keys.data, .size = keys.size };
  return nvim_input(nvim_keys);
}

void nvims_input_mouse(nvim_string_t button, nvim_string_t action, nvim_string_t modifier, int64_t grid, int64_t row, int64_t col)
{
  String nvim_button = { .data = button.data, .size = button.size };
  String nvim_action = { .data = action.data, .size = action.size };
  String nvim_modifier = { .data = modifier.data, .size = modifier.size };
  
  Error err;
  nvim_input_mouse(nvim_button, nvim_action, nvim_modifier, grid, row, col, &err);
  if (err.type != kErrorTypeNone) {
    printf("nvims_input_mouse error: %s\n", err.msg);
  }
}
