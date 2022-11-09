#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static _Bool parse_float_anchor(String anchor, FloatAnchor *out);
static _Bool parse_float_relative(String relative, FloatRelative *out);
static _Bool parse_float_bufpos(Array bufpos, lpos_T *out);
static void parse_border_title(Object title, Object title_pos, FloatConfig *fconfig, Error *err);
static _Bool parse_title_pos(Object title_pos, FloatConfig *fconfig, Error *err);
static void parse_border_style(Object style, FloatConfig *fconfig, Error *err);
static _Bool parse_float_config(Dict(float_config) *config, FloatConfig *fconfig, _Bool reconf, _Bool new_win, Error *err);
#include "nvim/func_attr.h"
