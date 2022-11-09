#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static _Bool msgpack_rpc_to_string(const msgpack_object *const obj, String *const arg) FUNC_ATTR_NONNULL_ALL;
static void msgpack_rpc_from_handle(ObjectType type, Integer o, msgpack_packer *res) FUNC_ATTR_NONNULL_ARG(3);
static _Bool msgpack_rpc_is_notification(msgpack_object *req);
static msgpack_object *msgpack_rpc_msg_id(msgpack_object *req);
#include "nvim/func_attr.h"
