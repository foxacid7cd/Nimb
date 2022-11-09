#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void free_channel_event(void **argv);
static void channel_destroy_early(Channel *chan);
static void close_cb(Stream *stream, void *data);
static inline list_T *buffer_to_tv_list(const char *const buf, const size_t len) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_ALWAYS_INLINE;
static void on_channel_output(Stream *stream, Channel *chan, RBuffer *buf, size_t count, _Bool eof, CallbackReader *reader);
static void schedule_channel_event(Channel *chan);
static void on_channel_event(void **args);
static void channel_process_exit_cb(Process *proc, int status, void *data);
static void channel_callback_call(Channel *chan, CallbackReader *reader);
static void term_write(char *buf, size_t size, void *data);
static void term_resize(uint16_t width, uint16_t height, void *data);
static inline void term_delayed_free(void **argv);
static void term_close(void *data);
static void set_info_event(void **argv);
#include "nvim/func_attr.h"
