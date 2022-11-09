#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void api_parse_enter(mpack_parser_t *parser, mpack_node_t *node);
static void api_parse_exit(mpack_parser_t *parser, mpack_node_t *node);
#include "nvim/func_attr.h"
