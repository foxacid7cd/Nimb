#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int validate_option_value_args(Dict(option) *opts, int *scope, int *opt_type, void **from, Error *err);
static getoption_T access_option_value(char *key, long *numval, char **stringval, int opt_flags, _Bool get, Error *err);
static getoption_T access_option_value_for(char *key, long *numval, char **stringval, int opt_flags, int opt_type, void *from, _Bool get, Error *err);
#include "nvim/func_attr.h"
