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
DLLEXPORT memfile_T *mf_open(char *fname, int flags);
DLLEXPORT int mf_open_file(memfile_T *mfp, char *fname);
DLLEXPORT void mf_close(memfile_T *mfp, _Bool del_file);
DLLEXPORT void mf_close_file(buf_T *buf, _Bool getlines);
DLLEXPORT void mf_new_page_size(memfile_T *mfp, unsigned new_size);
DLLEXPORT bhdr_T *mf_new(memfile_T *mfp, _Bool negative, unsigned page_count);
DLLEXPORT bhdr_T *mf_get(memfile_T *mfp, blocknr_T nr, unsigned page_count);
DLLEXPORT void mf_put(memfile_T *mfp, bhdr_T *hp, _Bool dirty, _Bool infile);
DLLEXPORT void mf_free(memfile_T *mfp, bhdr_T *hp);
DLLEXPORT int mf_sync(memfile_T *mfp, int flags);
DLLEXPORT void mf_set_dirty(memfile_T *mfp);
DLLEXPORT _Bool mf_release_all(void);
DLLEXPORT blocknr_T mf_trans_del(memfile_T *mfp, blocknr_T old_nr);
DLLEXPORT void mf_free_fnames(memfile_T *mfp);
DLLEXPORT void mf_set_fnames(memfile_T *mfp, char *fname);
DLLEXPORT void mf_fullname(memfile_T *mfp);
DLLEXPORT _Bool mf_need_trans(memfile_T *mfp);
#include "nvim/func_attr.h"
