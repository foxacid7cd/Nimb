#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void init_function_metadata(Dictionary *metadata);
static void init_ui_event_metadata(Dictionary *metadata);
static void init_error_type_metadata(Dictionary *metadata);
static void init_type_metadata(Dictionary *metadata);
#include "nvim/func_attr.h"
