#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static inline void ctx_save_regs(Context *ctx) FUNC_ATTR_NONNULL_ALL;
static inline void ctx_restore_regs(Context *ctx) FUNC_ATTR_NONNULL_ALL;
static inline void ctx_save_jumps(Context *ctx) FUNC_ATTR_NONNULL_ALL;
static inline void ctx_restore_jumps(Context *ctx) FUNC_ATTR_NONNULL_ALL;
static inline void ctx_save_bufs(Context *ctx) FUNC_ATTR_NONNULL_ALL;
static inline void ctx_restore_bufs(Context *ctx) FUNC_ATTR_NONNULL_ALL;
static inline void ctx_save_gvars(Context *ctx) FUNC_ATTR_NONNULL_ALL;
static inline void ctx_restore_gvars(Context *ctx) FUNC_ATTR_NONNULL_ALL;
static inline void ctx_save_funcs(Context *ctx, _Bool scriptonly) FUNC_ATTR_NONNULL_ALL;
static inline void ctx_restore_funcs(Context *ctx) FUNC_ATTR_NONNULL_ALL;
static inline Array sbuf_to_array(msgpack_sbuffer sbuf);
static inline msgpack_sbuffer array_to_sbuf(Array array);
#include "nvim/func_attr.h"
