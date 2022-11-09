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
DLLEXPORT char *parse_printoptions(void);
DLLEXPORT char *parse_printmbfont(void);
DLLEXPORT int prt_header_height(void);
DLLEXPORT int prt_use_number(void);
DLLEXPORT int prt_get_unit(int idx);
DLLEXPORT void ex_hardcopy(exarg_T *eap);
DLLEXPORT void mch_print_cleanup(void);
DLLEXPORT int mch_print_init(prt_settings_T *psettings, char_u *jobname, int forceit);
DLLEXPORT _Bool mch_print_begin(prt_settings_T *psettings);
DLLEXPORT void mch_print_end(prt_settings_T *psettings);
DLLEXPORT int mch_print_end_page(void);
DLLEXPORT int mch_print_begin_page(char_u *str);
DLLEXPORT int mch_print_blank_page(void);
DLLEXPORT void mch_print_start_line(const _Bool margin, const int page_line);
DLLEXPORT int mch_print_text_out(char_u *const textp, size_t len);
DLLEXPORT void mch_print_set_font(const TriState iBold, const TriState iItalic, const TriState iUnderline);
DLLEXPORT void mch_print_set_bg(uint32_t bgcol);
DLLEXPORT void mch_print_set_fg(uint32_t fgcol);
#include "nvim/func_attr.h"
