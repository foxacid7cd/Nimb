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
DLLEXPORT list_T *decode_create_map_special_dict(typval_T *const ret_tv, const ptrdiff_t len) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT typval_T decode_string(const char *const s, const size_t len, const TriState hasnul, const _Bool binary, const _Bool s_allocated) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT int json_decode_string(const char *const buf, const size_t buf_len, typval_T *const rettv) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT int msgpack_to_vim(const msgpack_object mobj, typval_T *const rettv) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
#include "nvim/func_attr.h"
