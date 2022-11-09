#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int line_off2cells(schar_T *line, size_t off, size_t max_off);
static int grid_off2cells(ScreenGrid *grid, size_t off, size_t max_off);
static int grid_char_needs_redraw(ScreenGrid *grid, size_t off_from, size_t off_to, int cols);
static void linecopy(ScreenGrid *grid, int to, int from, int col, int width);
#include "nvim/func_attr.h"
