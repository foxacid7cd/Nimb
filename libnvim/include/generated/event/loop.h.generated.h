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
DLLEXPORT void loop_init(Loop *loop, void *data);
DLLEXPORT _Bool loop_uv_run(Loop *loop, int ms, _Bool once);
DLLEXPORT _Bool loop_poll_events(Loop *loop, int ms);
DLLEXPORT void loop_schedule_fast(Loop *loop, Event event);
DLLEXPORT void loop_schedule_deferred(Loop *loop, Event event);
DLLEXPORT void loop_on_put(MultiQueue *queue, void *data);
DLLEXPORT _Bool loop_close(Loop *loop, _Bool wait);
DLLEXPORT void loop_purge(Loop *loop);
DLLEXPORT size_t loop_size(Loop *loop);
#include "nvim/func_attr.h"
