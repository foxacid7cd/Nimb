#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static Channel *find_rpc_channel(uint64_t id);
static void receive_msgpack(Stream *stream, RBuffer *rbuf, size_t c, void *data, _Bool eof);
static void parse_msgpack(Channel *channel);
static void handle_request(Channel *channel, Unpacker *p, Array args) FUNC_ATTR_NONNULL_ALL;
static void request_event(void **argv);
static _Bool channel_write(Channel *channel, WBuffer *buffer);
static void internal_read_event(void **argv);
static void send_error(Channel *chan, MessageType type, uint32_t id, char *err);
static void send_request(Channel *channel, uint32_t id, const char *name, Array args);
static void send_event(Channel *channel, const char *name, Array args);
static void broadcast_event(const char *name, Array args);
static void unsubscribe(Channel *channel, char *event);
static void exit_delay_cb(uv_timer_t *handle);
static void exit_event(void **argv);
static void chan_close_with_error(Channel *channel, char *msg, int loglevel);
static WBuffer *serialize_request(uint64_t channel_id, uint32_t request_id, const String method, Array args, msgpack_sbuffer *sbuffer, size_t refcount);
static WBuffer *serialize_response(uint64_t channel_id, MessageType type, uint32_t response_id, Error *err, Object arg, msgpack_sbuffer *sbuffer);
#include "nvim/func_attr.h"
