#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static _Bool check_autocmd_string_array(Array arr, char *k, Error *err);
static _Bool unpack_string_or_array(Array *array, Object *v, char *k, _Bool required, Error *err);
static int get_augroup_from_object(Object group, Error *err);
static _Bool get_patterns_from_pattern_or_buf(Array *patterns, Object pattern, Object buffer, Error *err);
static _Bool clear_autocmd(event_T event, char *pat, int au_group, Error *err);
#include "nvim/func_attr.h"
