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
DLLEXPORT void try_to_free_memory(void);
DLLEXPORT void *try_malloc(size_t size) FUNC_ATTR_MALLOC FUNC_ATTR_ALLOC_SIZE(1);
DLLEXPORT void *verbose_try_malloc(size_t size) FUNC_ATTR_MALLOC FUNC_ATTR_ALLOC_SIZE(1);
DLLEXPORT void *xmalloc(size_t size) FUNC_ATTR_MALLOC FUNC_ATTR_ALLOC_SIZE(1) FUNC_ATTR_NONNULL_RET;
DLLEXPORT void xfree(void *ptr);
DLLEXPORT void *xcalloc(size_t count, size_t size) FUNC_ATTR_MALLOC FUNC_ATTR_ALLOC_SIZE_PROD(1, 2) FUNC_ATTR_NONNULL_RET;
DLLEXPORT void *xrealloc(void *ptr, size_t size) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_ALLOC_SIZE(2) FUNC_ATTR_NONNULL_RET;
DLLEXPORT void *xmallocz(size_t size) FUNC_ATTR_MALLOC FUNC_ATTR_NONNULL_RET FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void *xmemdupz(const void *data, size_t len) FUNC_ATTR_MALLOC FUNC_ATTR_NONNULL_RET FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
DLLEXPORT char *xstrchrnul(const char *str, char c) FUNC_ATTR_NONNULL_RET FUNC_ATTR_NONNULL_ALL FUNC_ATTR_PURE;
DLLEXPORT void *xmemscan(const void *addr, char c, size_t size) FUNC_ATTR_NONNULL_RET FUNC_ATTR_NONNULL_ALL FUNC_ATTR_PURE;
DLLEXPORT void strchrsub(char *str, char c, char x) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void memchrsub(void *data, char c, char x, size_t len) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT size_t strcnt(const char *str, char c) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_PURE;
DLLEXPORT size_t memcnt(const void *data, char c, size_t len) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_PURE;
DLLEXPORT char *xstpcpy(char *restrict dst, const char *restrict src) FUNC_ATTR_NONNULL_RET FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
DLLEXPORT char *xstpncpy(char *restrict dst, const char *restrict src, size_t maxlen) FUNC_ATTR_NONNULL_RET FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
DLLEXPORT size_t xstrlcpy(char *restrict dst, const char *restrict src, size_t dsize) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT size_t xstrlcat(char *const dst, const char *const src, const size_t dsize) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT char *xstrdup(const char *str) FUNC_ATTR_MALLOC FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_RET FUNC_ATTR_NONNULL_ALL;
DLLEXPORT char *xstrdupnul(const char *const str) FUNC_ATTR_MALLOC FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_RET;
DLLEXPORT void *xmemrchr(const void *src, uint8_t c, size_t len) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_PURE;
DLLEXPORT char *xstrndup(const char *str, size_t len) FUNC_ATTR_MALLOC FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_RET FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void *xmemdup(const void *data, size_t len) FUNC_ATTR_MALLOC FUNC_ATTR_ALLOC_SIZE(2) FUNC_ATTR_NONNULL_RET FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool strequal(const char *a, const char *b) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT _Bool striequal(const char *a, const char *b) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void do_outofmem_msg(size_t size);
DLLEXPORT void time_to_bytes(time_t time_, uint8_t buf[8]);
DLLEXPORT ArenaMem arena_finish(Arena *arena);
DLLEXPORT void alloc_block(Arena *arena);
DLLEXPORT void *arena_alloc(Arena *arena, size_t size, _Bool align);
DLLEXPORT void arena_mem_free(ArenaMem mem);
DLLEXPORT char *arena_memdupz(Arena *arena, const char *buf, size_t size);
#include "nvim/func_attr.h"
