#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void discard_pending_return(typval_T *p);
static void free_msglist(msglist_T *l);
static int throw_exception(void *value, except_type_T type, char *cmdname);
static void discard_exception(except_T *excp, _Bool was_finished);
static void catch_exception(except_T *excp);
static void finish_exception(except_T *excp);
static void report_pending(int action, int pending, void *value);
static char *get_end_emsg(cstack_T *cstack);
#include "nvim/func_attr.h"
