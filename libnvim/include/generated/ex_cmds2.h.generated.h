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
DLLEXPORT void ex_ruby(exarg_T *eap);
DLLEXPORT void ex_rubyfile(exarg_T *eap);
DLLEXPORT void ex_rubydo(exarg_T *eap);
DLLEXPORT void ex_python3(exarg_T *eap);
DLLEXPORT void ex_py3file(exarg_T *eap);
DLLEXPORT void ex_pydo3(exarg_T *eap);
DLLEXPORT void ex_perl(exarg_T *eap);
DLLEXPORT void ex_perlfile(exarg_T *eap);
DLLEXPORT void ex_perldo(exarg_T *eap);
DLLEXPORT int autowrite(buf_T *buf, int forceit);
DLLEXPORT void autowrite_all(void);
DLLEXPORT _Bool check_changed(buf_T *buf, int flags);
DLLEXPORT void dialog_changed(buf_T *buf, _Bool checkall);
DLLEXPORT _Bool dialog_close_terminal(buf_T *buf);
DLLEXPORT _Bool can_abandon(buf_T *buf, int forceit);
DLLEXPORT _Bool check_changed_any(_Bool hidden, _Bool unload);
DLLEXPORT int check_fname(void);
DLLEXPORT int buf_write_all(buf_T *buf, int forceit);
DLLEXPORT void ex_listdo(exarg_T *eap);
DLLEXPORT void ex_compiler(exarg_T *eap);
DLLEXPORT void ex_checktime(exarg_T *eap);
DLLEXPORT void ex_drop(exarg_T *eap);
#include "nvim/func_attr.h"
