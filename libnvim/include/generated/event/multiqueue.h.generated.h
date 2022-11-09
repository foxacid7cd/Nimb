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
DLLEXPORT MultiQueue *multiqueue_new_parent(PutCallback put_cb, void *data);
DLLEXPORT MultiQueue *multiqueue_new_child(MultiQueue *parent) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void multiqueue_free(MultiQueue *this);
DLLEXPORT Event multiqueue_get(MultiQueue *this);
DLLEXPORT void multiqueue_put_event(MultiQueue *this, Event event);
DLLEXPORT void multiqueue_process_events(MultiQueue *this);
DLLEXPORT void multiqueue_purge_events(MultiQueue *this);
DLLEXPORT _Bool multiqueue_empty(MultiQueue *this);
DLLEXPORT void multiqueue_replace_parent(MultiQueue *this, MultiQueue *new_parent);
DLLEXPORT size_t multiqueue_size(MultiQueue *this);
DLLEXPORT Event event_create_oneshot(Event ev, int num);
#include "nvim/func_attr.h"
