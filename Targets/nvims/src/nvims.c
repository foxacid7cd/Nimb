//
//  nvims.c
//  nvims
//
//  Created by Yevhenii Matviienko on 11.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#include <nvim/api/vim.h>
#include <nvim/main.h>
#include <nvim/mbyte.h>
#include <uv.h>
#include "nvims.h"

extern Loop main_loop;
extern int nvim_main(int argc, char **argv);

nvims_ui_t nvims_ui;
uv_thread_t nvim_thread;

void nvim_thread_main(void *arg) {
  char *nvim_arg = "nvim";

  nvim_main(1, &nvim_arg);
}

void nvims_start(nvims_ui_t arg) {
  nvims_ui = arg;
  uv_thread_create(&nvim_thread, nvim_thread_main, NULL);
}

int64_t nvims_input(nvim_string_t keys) {
  return nvim_input(*(String *)&keys);
}

void nvims_input_mouse(nvim_string_t button, nvim_string_t action, nvim_string_t modifier, int64_t grid, int64_t row, int64_t col) {
  Error err;

  nvim_input_mouse(*(String *)&button, *(String *)&action, *(String *)&modifier, grid, row, col, &err);

  if (err.type != kErrorTypeNone) {
    printf("nvims_input_mouse error: %s\n", err.msg);
  }
}

int nvims_utf_ptr2char(const char *const p_in) {
  return utf_ptr2char(p_in);
}
