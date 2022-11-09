#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static char_u *get_buffcont(buffheader_T *buffer, int dozero);
static void add_buff(buffheader_T *const buf, const char *const s, ptrdiff_t slen);
static void delete_buff_tail(buffheader_T *buf, int slen);
static void add_num_buff(buffheader_T *buf, long n);
static void add_char_buff(buffheader_T *buf, int c);
static int read_readbuffers(int advance);
static int read_readbuf(buffheader_T *buf, int advance);
static void start_stuff(void);
static int read_redo(_Bool init, _Bool old_redo);
static void copy_redo(_Bool old_redo);
static void init_typebuf(void);
static void gotchars(const char_u *chars, size_t len) FUNC_ATTR_NONNULL_ALL;
static _Bool can_get_old_char(void);
static void closescript(void);
static void updatescript(int c);
static void getchar_common(typval_T *argvars, typval_T *rettv) FUNC_ATTR_NONNULL_ALL;
static int put_string_in_typebuf(int offset, int slen, char_u *string, int new_slen);
static _Bool at_ins_compl_key(void);
static int check_simplify_modifier(int max_offset);
static int handle_mapping(int *keylenp, const _Bool *timedout, int *mapdepth);
static int vgetorpeek(_Bool advance);
static _Bool typebuf_match_len(const uint8_t *str, int *mlen);
#include "nvim/func_attr.h"
