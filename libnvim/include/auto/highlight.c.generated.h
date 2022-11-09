#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int get_attr_entry(HlEntry entry);
static HlAttrs get_colors_force(int attr);
static int rgb_blend(int ratio, int rgb1, int rgb2);
static int cterm_blend(int ratio, int c1, int c2);
static int hl_rgb2cterm_color(int rgb);
static int hl_cterm2rgb_color(int nr);
static void hl_inspect_impl(Array *arr, int attr);
#include "nvim/func_attr.h"
