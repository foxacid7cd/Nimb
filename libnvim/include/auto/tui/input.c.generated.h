#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void tinput_done_event(void **argv);
static void tinput_wait_enqueue(void **argv);
static void tinput_paste_event(void **argv);
static void tinput_flush(TermInput *input, _Bool wait_until_empty);
static void tinput_enqueue(TermInput *input, char *buf, size_t size);
static void handle_kitty_key_protocol(TermInput *input, TermKeyKey *key);
static void forward_simple_utf8(TermInput *input, TermKeyKey *key);
static void forward_modified_utf8(TermInput *input, TermKeyKey *key);
static void forward_mouse_event(TermInput *input, TermKeyKey *key);
static TermKeyResult tk_getkey(TermKey *tk, TermKeyKey *key, _Bool force);
static void tk_getkeys(TermInput *input, _Bool force);
static void tinput_timer_cb(TimeWatcher *watcher, void *data);
static _Bool handle_focus_event(TermInput *input);
static HandleState handle_bracketed_paste(TermInput *input);
static void set_bg_deferred(void **argv);
static HandleState handle_background_color(TermInput *input);
static void handle_raw_buffer(TermInput *input, _Bool force);
static void tinput_read_cb(Stream *stream, RBuffer *buf, size_t count_, void *data, _Bool eof);
#include "nvim/func_attr.h"
