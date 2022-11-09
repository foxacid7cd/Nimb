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
DLLEXPORT void *vim_findfile_init(char *path, char *filename, char *stopdirs, int level, int free_visited, int find_what, void *search_ctx_arg, int tagfile, char *rel_fname);
DLLEXPORT char_u *vim_findfile_stopdir(char_u *buf);
DLLEXPORT void vim_findfile_cleanup(void *ctx);
DLLEXPORT char_u *vim_findfile(void *search_ctx_arg);
DLLEXPORT void vim_findfile_free_visited(void *search_ctx_arg);
DLLEXPORT char_u *find_file_in_path(char_u *ptr, size_t len, int options, int first, char_u *rel_fname);
DLLEXPORT char_u *find_directory_in_path(char_u *ptr, size_t len, int options, char_u *rel_fname);
DLLEXPORT char_u *find_file_in_path_option(char_u *ptr, size_t len, int options, int first, char_u *path_option, int find_what, char_u *rel_fname, char_u *suffixes);
DLLEXPORT void do_autocmd_dirchanged(char *new_dir, CdScope scope, CdCause cause, _Bool pre);
DLLEXPORT int vim_chdirfile(char *fname, CdCause cause);
DLLEXPORT int vim_chdir(char_u *new_dir);
#include "nvim/func_attr.h"
