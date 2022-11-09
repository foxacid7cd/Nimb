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
DLLEXPORT int stream_set_blocking(int fd, _Bool blocking);
DLLEXPORT void stream_init(Loop *loop, Stream *stream, int fd, uv_stream_t *uvstream) FUNC_ATTR_NONNULL_ARG(2);
DLLEXPORT void stream_close(Stream *stream, stream_close_cb on_stream_close, void *data) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT void stream_may_close(Stream *stream);
DLLEXPORT void stream_close_handle(Stream *stream) FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
