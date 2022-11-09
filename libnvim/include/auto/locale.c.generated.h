#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static char *get_locale_val(int what);
static _Bool is_valid_mess_lang(const char *lang);
static char *get_mess_env(void);
static char **find_locales(void);
static void init_locales(void);
#include "nvim/func_attr.h"
