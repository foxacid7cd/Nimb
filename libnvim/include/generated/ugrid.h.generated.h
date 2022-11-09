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
DLLEXPORT void ugrid_init(UGrid *grid);
DLLEXPORT void ugrid_free(UGrid *grid);
DLLEXPORT void ugrid_resize(UGrid *grid, int width, int height);
DLLEXPORT void ugrid_clear(UGrid *grid);
DLLEXPORT void ugrid_clear_chunk(UGrid *grid, int row, int col, int endcol, sattr_T attr);
DLLEXPORT void ugrid_goto(UGrid *grid, int row, int col);
DLLEXPORT void ugrid_scroll(UGrid *grid, int top, int bot, int left, int right, int count);
#include "nvim/func_attr.h"
