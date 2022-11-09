#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static _Bool menu_is_winbar(const char *const name) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
static vimmenu_T **get_root_menu(const char *const name) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
static int add_menu_path(const char *const menu_path, vimmenu_T *menuarg, const long *const pri_tab, const char *const call_data);
static int menu_enable_recurse(vimmenu_T *menu, char *name, int modes, int enable);
static int remove_menu(vimmenu_T **menup, char *name, int modes, _Bool silent);
static void free_menu(vimmenu_T **menup);
static void free_menu_string(vimmenu_T *menu, int idx);
static dict_T *menu_get_recursive(const vimmenu_T *menu, int modes);
static vimmenu_T *find_menu(vimmenu_T *menu, char *name, int modes);
static int show_menus(char *const path_name, int modes);
static void show_menus_recursive(vimmenu_T *menu, int modes, int depth);
static _Bool menu_name_equal(const char *const name, const vimmenu_T *const menu);
static _Bool menu_namecmp(const char *const name, const char *const mname);
static char *get_menu_mode_str(int modes);
static char *popup_mode_name(char *name, int idx);
static char *menu_text(const char *str, int *mnemonic, char **actext) FUNC_ATTR_NONNULL_RET FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ARG(1);
static int menu_is_hidden(char *name);
static int get_menu_mode(void);
static vimmenu_T *menu_getbyname(char *name_arg) FUNC_ATTR_NONNULL_ALL;
static char *menu_skip_part(char *p);
static char *menutrans_lookup(char *name, int len);
static void menu_unescape_name(char *name);
static char *menu_translate_tab_and_shift(char *arg_start);
static void menuitem_getinfo(const char *menu_name, const vimmenu_T *menu, int modes, dict_T *dict) FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
