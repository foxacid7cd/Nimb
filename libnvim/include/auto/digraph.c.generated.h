#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int getexactdigraph(int char1, int char2, _Bool meta_char) FUNC_ATTR_PURE;
static void registerdigraph(int char1, int char2, int n);
static void digraph_header(const char *msg) FUNC_ATTR_NONNULL_ALL;
static void digraph_getlist_appendpair(const digr_T *dp, list_T *l);
static void printdigraph(const digr_T *dp, result_T *previous) FUNC_ATTR_NONNULL_ARG(1);
static int get_digraph_chars(const typval_T *arg, int *char1, int *char2);
static _Bool digraph_set_common(const typval_T *argchars, const typval_T *argdigraph);
static void keymap_unload(void);
#include "nvim/func_attr.h"
