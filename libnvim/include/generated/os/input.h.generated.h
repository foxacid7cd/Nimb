#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
#ifndef DLLEXPORT
#  ifdef MSWIN
#    define DLLEXPORT __declspec(dllexport)
#  else
#    define DLLEXPORT
#  endif
#endif
DLLEXPORT void input_init(void);
DLLEXPORT void input_global_fd_init(int fd);
DLLEXPORT int input_global_fd(void);
DLLEXPORT void input_start(int fd);
DLLEXPORT void input_stop(void);
DLLEXPORT int os_inchar(uint8_t *buf, int maxlen, int ms, int tb_change_cnt, MultiQueue *events);
DLLEXPORT _Bool os_char_avail(void);
DLLEXPORT void os_breakcheck(void);
DLLEXPORT void line_breakcheck(void);
DLLEXPORT void fast_breakcheck(void);
DLLEXPORT void veryfast_breakcheck(void);
DLLEXPORT _Bool os_isatty(int fd);
DLLEXPORT size_t input_enqueue(String keys);
DLLEXPORT size_t input_enqueue_mouse(int code, uint8_t modifier, int grid, int row, int col);
DLLEXPORT _Bool input_blocking(void);
DLLEXPORT void input_done(void);
DLLEXPORT _Bool input_available(void);
#include "nvim/func_attr.h"
