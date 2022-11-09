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
DLLEXPORT int runtime_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_runtime_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int get_commands_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_get_commands_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int highlight_cterm_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_highlight_cterm_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int clear_autocmds_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_clear_autocmds_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int option_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_option_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int create_autocmd_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_create_autocmd_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int highlight_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_highlight_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int cmd_mods_filter_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_cmd_mods_filter_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int exec_autocmds_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_exec_autocmds_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int get_autocmds_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_get_autocmds_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int create_augroup_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_create_augroup_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int context_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_context_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int set_decoration_provider_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_set_decoration_provider_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int cmd_opts_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_cmd_opts_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int cmd_mods_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_cmd_mods_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int keymap_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_keymap_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int cmd_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_cmd_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int cmd_magic_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_cmd_magic_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int float_config_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_float_config_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int set_extmark_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_set_extmark_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int user_command_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_user_command_get_field(void *retval, const char *str, size_t len);
DLLEXPORT int eval_statusline_hash(const char *str, size_t len);
DLLEXPORT Object *KeyDict_eval_statusline_get_field(void *retval, const char *str, size_t len);
#include "nvim/func_attr.h"
