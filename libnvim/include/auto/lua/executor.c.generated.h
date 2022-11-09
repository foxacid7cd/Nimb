#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void nlua_error(lua_State *const lstate, const char *const msg) FUNC_ATTR_NONNULL_ALL;
static int nlua_pcall(lua_State *lstate, int nargs, int nresults);
static int nlua_nvim_version(lua_State *const lstate) FUNC_ATTR_NONNULL_ALL;
static void nlua_luv_error_event(void **argv);
static int nlua_luv_cfpcall(lua_State *lstate, int nargs, int nresult, int flags) FUNC_ATTR_NONNULL_ALL;
static int nlua_luv_thread_cb_cfpcall(lua_State *lstate, int nargs, int nresult, int flags);
static int nlua_luv_thread_cfpcall(lua_State *lstate, int nargs, int nresult, int flags) FUNC_ATTR_NONNULL_ALL;
static int nlua_luv_thread_cfcpcall(lua_State *lstate, lua_CFunction func, void *ud, int flags) FUNC_ATTR_NONNULL_ARG(1, 2);
static int nlua_luv_thread_common_cfpcall(lua_State *lstate, int nargs, int nresult, int flags, _Bool is_callback) FUNC_ATTR_NONNULL_ALL;
static int nlua_thr_api_nvim__get_runtime(lua_State *lstate);
static void nlua_schedule_event(void **argv);
static int nlua_schedule(lua_State *const lstate) FUNC_ATTR_NONNULL_ALL;
static void dummy_timer_due_cb(TimeWatcher *tw, void *data);
static void dummy_timer_close_cb(TimeWatcher *tw, void *data);
static _Bool nlua_wait_condition(lua_State *lstate, int *status, _Bool *callback_result);
static int nlua_wait(lua_State *lstate) FUNC_ATTR_NONNULL_ALL;
static nlua_ref_state_t *nlua_new_ref_state(lua_State *lstate, _Bool is_thread) FUNC_ATTR_NONNULL_ALL;
static nlua_ref_state_t *nlua_get_ref_state(lua_State *lstate) FUNC_ATTR_NONNULL_ALL;
static void nlua_common_vim_init(lua_State *lstate, _Bool is_thread) FUNC_ATTR_NONNULL_ARG(1);
static int nlua_module_preloader(lua_State *lstate);
static _Bool nlua_init_packages(lua_State *lstate) FUNC_ATTR_NONNULL_ALL;
static int nlua_ui_attach(lua_State *lstate) FUNC_ATTR_NONNULL_ALL;
static int nlua_ui_detach(lua_State *lstate) FUNC_ATTR_NONNULL_ALL;
static _Bool nlua_state_init(lua_State *const lstate) FUNC_ATTR_NONNULL_ALL;
static lua_State *nlua_thread_acquire_vm(void);
static void nlua_common_free_all_mem(lua_State *lstate) FUNC_ATTR_NONNULL_ALL;
static void nlua_print_event(void **argv);
static int nlua_print(lua_State *const lstate) FUNC_ATTR_NONNULL_ALL;
static int nlua_require(lua_State *const lstate) FUNC_ATTR_NONNULL_ALL;
static int nlua_debug(lua_State *lstate) FUNC_ATTR_NONNULL_ALL;
static _Bool viml_func_is_fast(const char *name);
static int nlua_rpcrequest(lua_State *lstate);
static int nlua_rpcnotify(lua_State *lstate);
static int nlua_rpc(lua_State *lstate, _Bool request);
static int nlua_nil_tostring(lua_State *lstate);
static int nlua_empty_dict_tostring(lua_State *lstate);
static void nlua_typval_exec(const char *lcmd, size_t lcmd_len, const char *name, typval_T *const args, int argcount, _Bool special, typval_T *ret_tv);
static void nlua_add_treesitter(lua_State *const lstate) FUNC_ATTR_NONNULL_ALL;
static int nlua_is_thread(lua_State *lstate);
#include "nvim/func_attr.h"
