#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void add_user(garray_T *users, char *user, _Bool need_copy);
static void init_users(void);
#include "nvim/func_attr.h"
