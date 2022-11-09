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
DLLEXPORT void pty_process_save_termios(int tty_fd);
DLLEXPORT int pty_process_spawn(PtyProcess *ptyproc) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT const char *pty_process_tty_name(PtyProcess *ptyproc);
DLLEXPORT void pty_process_resize(PtyProcess *ptyproc, uint16_t width, uint16_t height) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void pty_process_close(PtyProcess *ptyproc) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void pty_process_close_master(PtyProcess *ptyproc) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void pty_process_teardown(Loop *loop);
#include "nvim/func_attr.h"
