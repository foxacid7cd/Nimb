#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void init_child(PtyProcess *ptyproc) FUNC_ATTR_NONNULL_ALL;
static void init_termios(struct termios *termios) FUNC_ATTR_NONNULL_ALL;
static int set_duplicating_descriptor(int fd, uv_pipe_t *pipe) FUNC_ATTR_NONNULL_ALL;
static void chld_handler(uv_signal_t *handle, int signum);
#include "nvim/func_attr.h"
