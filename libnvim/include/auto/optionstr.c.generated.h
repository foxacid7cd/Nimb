#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static char *illegal_char(char *errbuf, size_t errbuflen, int c);
static void set_string_option_global(vimoption_T *opt, char **varp);
static _Bool valid_filetype(const char *val) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
static char *check_mousescroll(char *string);
static int check_signcolumn(char *val);
static int check_opt_strings(char *val, char **values, int list);
static int opt_strings_flags(char *val, char **values, unsigned *flagp, _Bool list);
#include "nvim/func_attr.h"
