#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int regex_match(lua_State *lstate, regprog_T **prog, char_u *str);
static int regex_match_str(lua_State *lstate);
static int regex_match_line(lua_State *lstate);
static regprog_T **regex_check(lua_State *L);
static int regex_gc(lua_State *lstate);
static int regex_tostring(lua_State *lstate);
static int nlua_str_utf_pos(lua_State *const lstate) FUNC_ATTR_NONNULL_ALL;
static int nlua_str_utf_start(lua_State *const lstate) FUNC_ATTR_NONNULL_ALL;
static int nlua_str_utf_end(lua_State *const lstate) FUNC_ATTR_NONNULL_ALL;
static dict_T *nlua_get_var_scope(lua_State *lstate);
static int nlua_stricmp(lua_State *const lstate) FUNC_ATTR_NONNULL_ALL;
static int nlua_iconv(lua_State *lstate);
#include "nvim/func_attr.h"
