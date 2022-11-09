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
DLLEXPORT RBuffer *rbuffer_new(size_t capacity) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_RET;
DLLEXPORT void rbuffer_free(RBuffer *buf);
DLLEXPORT size_t rbuffer_size(RBuffer *buf) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT size_t rbuffer_capacity(RBuffer *buf) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT size_t rbuffer_space(RBuffer *buf) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT char *rbuffer_write_ptr(RBuffer *buf, size_t *write_count) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void rbuffer_reset(RBuffer *buf) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void rbuffer_produced(RBuffer *buf, size_t count) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT char *rbuffer_read_ptr(RBuffer *buf, size_t *read_count) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void rbuffer_consumed(RBuffer *buf, size_t count) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void rbuffer_consumed_compact(RBuffer *buf, size_t count) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT size_t rbuffer_write(RBuffer *buf, const char *src, size_t src_size) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT size_t rbuffer_read(RBuffer *buf, char *dst, size_t dst_size) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT char *rbuffer_get(RBuffer *buf, size_t index) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_NONNULL_RET;
DLLEXPORT int rbuffer_cmp(RBuffer *buf, const char *str, size_t count) FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
