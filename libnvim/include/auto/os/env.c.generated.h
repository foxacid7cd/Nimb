#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static char *os_homedir(void);
static char *vim_version_dir(const char *vimdir);
static char *remove_tail(char *path, char *pend, char *dirname);
#include "nvim/func_attr.h"
