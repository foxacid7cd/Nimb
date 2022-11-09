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
DLLEXPORT int findsent(Direction dir, long count);
DLLEXPORT _Bool findpar(_Bool *pincl, int dir, long count, int what, _Bool both);
DLLEXPORT _Bool startPS(linenr_T lnum, int para, _Bool both);
DLLEXPORT int fwd_word(long count, _Bool bigword, _Bool eol);
DLLEXPORT int bck_word(long count, _Bool bigword, _Bool stop);
DLLEXPORT int end_word(long count, _Bool bigword, _Bool stop, _Bool empty);
DLLEXPORT int bckend_word(long count, _Bool bigword, _Bool eol);
DLLEXPORT int current_word(oparg_T *oap, long count, _Bool include, _Bool bigword);
DLLEXPORT int current_sent(oparg_T *oap, long count, _Bool include);
DLLEXPORT int current_block(oparg_T *oap, long count, _Bool include, int what, int other);
DLLEXPORT int current_tagblock(oparg_T *oap, long count_arg, _Bool include);
DLLEXPORT int current_par(oparg_T *oap, long count, _Bool include, int type);
DLLEXPORT _Bool current_quote(oparg_T *oap, long count, _Bool include, int quotechar) FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
