#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void ui_refresh_event(void **argv);
static void deferred_refresh_event(void **argv);
#include "nvim/func_attr.h"
