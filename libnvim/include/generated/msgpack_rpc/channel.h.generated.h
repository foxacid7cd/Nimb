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
DLLEXPORT void rpc_init(void);
DLLEXPORT void rpc_start(Channel *channel);
DLLEXPORT _Bool rpc_send_event(uint64_t id, const char *name, Array args);
DLLEXPORT Object rpc_send_call(uint64_t id, const char *method_name, Array args, ArenaMem *result_mem, Error *err);
DLLEXPORT void rpc_subscribe(uint64_t id, char *event);
DLLEXPORT void rpc_unsubscribe(uint64_t id, char *event);
DLLEXPORT _Bool rpc_write_raw(uint64_t id, WBuffer *buffer);
DLLEXPORT void rpc_close(Channel *channel);
DLLEXPORT void rpc_free(Channel *channel);
DLLEXPORT void rpc_set_client_info(uint64_t id, Dictionary info);
DLLEXPORT Dictionary rpc_client_info(Channel *chan);
DLLEXPORT const char *rpc_client_name(Channel *chan);
#include "nvim/func_attr.h"
