#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void cursorhold_event(void **argv);
static void create_cursorhold_event(_Bool events_enabled);
static void restart_cursorhold_wait(int tb_change_cnt);
static uint8_t check_multiclick(int code, int grid, int row, int col);
static unsigned int handle_mouse_event(char **ptr, uint8_t *buf, unsigned int bufsize);
static InbufPollResult inbuf_poll(int ms, MultiQueue *events);
static void input_read_cb(Stream *stream, RBuffer *buf, size_t c, void *data, _Bool at_eof);
static void process_ctrl_c(void);
static int push_event_key(uint8_t *buf, int maxlen);
static _Bool input_ready(MultiQueue *events);
static void read_error_exit(void) FUNC_ATTR_NORETURN;
static _Bool pending_events(MultiQueue *events);
#include "nvim/func_attr.h"
