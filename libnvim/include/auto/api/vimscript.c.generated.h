#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static Object _call_function(String fn, Array args, dict_T *self, Error *err);
#include "nvim/func_attr.h"
