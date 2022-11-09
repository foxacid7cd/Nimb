#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static inline void create_special_dict(typval_T *const rettv, const MessagePackType type, typval_T val) FUNC_ATTR_NONNULL_ALL;
static inline int json_decoder_pop(ValuesStackItem obj, ValuesStack *const stack, ContainerStack *const container_stack, const char **const pp, _Bool *const next_map_special, _Bool *const didcomma, _Bool *const didcolon) FUNC_ATTR_NONNULL_ALL;
static inline int parse_json_string(const char *const buf, const size_t buf_len, const char **const pp, ValuesStack *const stack, ContainerStack *const container_stack, _Bool *const next_map_special, _Bool *const didcomma, _Bool *const didcolon) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_ALWAYS_INLINE;
static inline int parse_json_number(const char *const buf, const size_t buf_len, const char **const pp, ValuesStack *const stack, ContainerStack *const container_stack, _Bool *const next_map_special, _Bool *const didcomma, _Bool *const didcolon) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_ALWAYS_INLINE;
#include "nvim/func_attr.h"
