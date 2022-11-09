#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int hl_has_settings(int idx, _Bool check_link);
static void highlight_clear(int idx);
static void highlight_list_one(const int id);
static _Bool highlight_list_arg(const int id, _Bool didh, const int type, int iarg, const char *sarg, const char *const name);
static void set_hl_attr(int idx);
static int syn_add_group(const char *name, size_t len);
static void combine_stl_hlt(int id, int id_S, int id_alt, int hlcnt, int i, int hlf, int *table) FUNC_ATTR_NONNULL_ALL;
static void highlight_list(void);
static void highlight_list_two(int cnt, int attr);
#include "nvim/func_attr.h"
