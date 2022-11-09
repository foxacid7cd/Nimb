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
DLLEXPORT void channel_teardown(void);
DLLEXPORT _Bool channel_close(uint64_t id, ChannelPart part, const char **error);
DLLEXPORT void channel_init(void);
DLLEXPORT Channel *channel_alloc(ChannelStreamType type) FUNC_ATTR_NONNULL_RET;
DLLEXPORT void channel_create_event(Channel *chan, const char *ext_source);
DLLEXPORT void channel_incref(Channel *chan);
DLLEXPORT void channel_decref(Channel *chan);
DLLEXPORT void callback_reader_free(CallbackReader *reader);
DLLEXPORT void callback_reader_start(CallbackReader *reader, const char *type);
DLLEXPORT Channel *channel_job_start(char **argv, CallbackReader on_stdout, CallbackReader on_stderr, Callback on_exit, _Bool pty, _Bool rpc, _Bool overlapped, _Bool detach, ChannelStdinMode stdin_mode, const char *cwd, uint16_t pty_width, uint16_t pty_height, dict_T *env, varnumber_T *status_out);
DLLEXPORT uint64_t channel_connect(_Bool tcp, const char *address, _Bool rpc, CallbackReader on_output, int timeout, const char **error);
DLLEXPORT void channel_from_connection(SocketWatcher *watcher);
DLLEXPORT uint64_t channel_from_stdio(_Bool rpc, CallbackReader on_output, const char **error) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT size_t channel_send(uint64_t id, char *data, size_t len, _Bool data_owned, const char **error) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void on_channel_data(Stream *stream, RBuffer *buf, size_t count, void *data, _Bool eof);
DLLEXPORT void on_job_stderr(Stream *stream, RBuffer *buf, size_t count, void *data, _Bool eof);
DLLEXPORT void channel_reader_callbacks(Channel *chan, CallbackReader *reader);
DLLEXPORT void channel_terminal_open(buf_T *buf, Channel *chan);
DLLEXPORT void channel_info_changed(Channel *chan, _Bool new);
DLLEXPORT _Bool channel_job_running(uint64_t id);
DLLEXPORT Dictionary channel_info(uint64_t id);
DLLEXPORT Array channel_all_info(void);
#include "nvim/func_attr.h"
