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
DLLEXPORT void event_init(void);
DLLEXPORT _Bool event_teardown(void);
DLLEXPORT void early_init(mparm_T *paramp);
DLLEXPORT int main(int argc, char **argv);
DLLEXPORT void os_exit(int r) FUNC_ATTR_NORETURN;
DLLEXPORT void getout(int exitval) FUNC_ATTR_NORETURN;
DLLEXPORT void preserve_exit(void) FUNC_ATTR_NORETURN;
#include "nvim/func_attr.h"
