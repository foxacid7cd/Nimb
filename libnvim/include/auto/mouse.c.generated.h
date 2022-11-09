#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int get_mouse_class(char_u *p);
static void find_start_of_word(pos_T *pos);
static void find_end_of_word(pos_T *pos);
static void move_tab_to_mouse(void);
static void call_click_def_func(StlClickDefinition *click_defs, int col, int which_button);
static int get_fpos_of_mouse(pos_T *mpos);
static _Bool mouse_model_popup(void);
static win_T *mouse_find_grid_win(int *gridp, int *rowp, int *colp);
static void set_mouse_topline(win_T *wp);
static colnr_T scroll_line_len(linenr_T lnum);
static linenr_T find_longest_lnum(void);
static int mouse_adjust_click(win_T *wp, int row, int col);
#include "nvim/func_attr.h"
