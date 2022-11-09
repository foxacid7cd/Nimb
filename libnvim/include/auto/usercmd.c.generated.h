#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static char *get_command_complete(int arg);
static void uc_list(char *name, size_t name_len);
static int uc_scan_attr(char *attr, size_t len, uint32_t *argt, long *def, int *flags, int *complp, char_u **compl_arg, cmd_addr_T *addr_type_arg) FUNC_ATTR_NONNULL_ALL;
static char *uc_split_args(char *arg, char **args, const size_t *arglens, size_t argc, size_t *lenp);
static size_t add_cmd_modifier(char *buf, char *mod_str, _Bool *multi_mods);
static size_t uc_check_code(char *code, size_t len, char *buf, ucmd_T *cmd, exarg_T *eap, char **split_buf, size_t *split_len);
#include "nvim/func_attr.h"
