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
DLLEXPORT void sha256_start(context_sha256_T *ctx);
DLLEXPORT void sha256_update(context_sha256_T *ctx, const char_u *input, size_t length);
DLLEXPORT void sha256_finish(context_sha256_T *ctx, char_u digest[32]);
DLLEXPORT const char *sha256_bytes(const uint8_t *restrict buf, size_t buf_len, const uint8_t *restrict salt, size_t salt_len);
DLLEXPORT _Bool sha256_self_test(void);
#include "nvim/func_attr.h"
