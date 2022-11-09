#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static LuaTableProps nlua_traverse_table(lua_State *const lstate) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
static inline void nlua_push_type_idx(lua_State *lstate) FUNC_ATTR_NONNULL_ALL;
static inline void nlua_push_val_idx(lua_State *lstate) FUNC_ATTR_NONNULL_ALL;
static inline void nlua_push_type(lua_State *lstate, ObjectType type) FUNC_ATTR_NONNULL_ALL;
static inline void nlua_create_typed_table(lua_State *lstate, const size_t narr, const size_t nrec, const ObjectType type) FUNC_ATTR_NONNULL_ALL;
static inline LuaTableProps nlua_check_type(lua_State *const lstate, Error *const err, const ObjectType type) FUNC_ATTR_NONNULL_ARG(1) FUNC_ATTR_WARN_UNUSED_RESULT;
static Array nlua_pop_Array_unchecked(lua_State *const lstate, const LuaTableProps table_props, Error *const err);
static Dictionary nlua_pop_Dictionary_unchecked(lua_State *lstate, const LuaTableProps table_props, _Bool ref, Error *err) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
#include "nvim/func_attr.h"
