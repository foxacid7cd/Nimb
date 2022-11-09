#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
#ifndef DLLEXPORT
#  ifdef MSWIN
#    define DLLEXPORT __declspec(dllexport)
#  else
#    define DLLEXPORT
#  endif
#endif
DLLEXPORT int shada_write_file(const char *const file, _Bool nomerge);
DLLEXPORT int shada_read_marks(void);
DLLEXPORT int shada_read_everything(const char *const fname, const _Bool forceit, const _Bool missing_ok);
DLLEXPORT void shada_encode_regs(msgpack_sbuffer *const sbuf) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void shada_encode_jumps(msgpack_sbuffer *const sbuf) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void shada_encode_buflist(msgpack_sbuffer *const sbuf) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void shada_encode_gvars(msgpack_sbuffer *const sbuf) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void shada_read_sbuf(msgpack_sbuffer *const sbuf, const int flags) FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
