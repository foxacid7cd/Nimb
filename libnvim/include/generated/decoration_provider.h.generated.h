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
DLLEXPORT void decor_providers_invoke_spell(win_T *wp, int start_row, int start_col, int end_row, int end_col, char **err);
DLLEXPORT void decor_providers_start(DecorProviders *providers, char **err);
DLLEXPORT void decor_providers_invoke_win(win_T *wp, DecorProviders *providers, DecorProviders *line_providers, char **err);
DLLEXPORT void decor_providers_invoke_line(win_T *wp, DecorProviders *providers, int row, _Bool *has_decor, char **err);
DLLEXPORT void decor_providers_invoke_buf(buf_T *buf, DecorProviders *providers, char **err);
DLLEXPORT void decor_providers_invoke_end(DecorProviders *providers, char **err);
DLLEXPORT DecorProvider *get_decor_provider(NS ns_id, _Bool force);
DLLEXPORT void decor_provider_clear(DecorProvider *p);
DLLEXPORT void decor_free_all_mem(void);
#include "nvim/func_attr.h"
