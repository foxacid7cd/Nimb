#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int foldLevel(linenr_T lnum);
static void newFoldLevelWin(win_T *wp);
static _Bool checkCloseRec(garray_T *gap, linenr_T lnum, int level);
static _Bool foldFind(const garray_T *gap, linenr_T lnum, fold_T **fpp);
static int foldLevelWin(win_T *wp, linenr_T lnum);
static void checkupdate(win_T *wp);
static void setFoldRepeat(pos_T pos, long count, int do_open);
static linenr_T setManualFold(pos_T pos, int opening, int recurse, int *donep);
static linenr_T setManualFoldWin(win_T *wp, linenr_T lnum, int opening, int recurse, int *donep);
static void foldOpenNested(fold_T *fpr);
static void deleteFoldEntry(win_T *const wp, garray_T *const gap, const int idx, const _Bool recursive);
static void foldMarkAdjustRecurse(win_T *wp, garray_T *gap, linenr_T line1, linenr_T line2, linenr_T amount, linenr_T amount_after);
static int getDeepestNestingRecurse(garray_T *gap);
static _Bool check_closed(win_T *const wp, fold_T *const fp, _Bool *const use_levelp, const int level, _Bool *const maybe_smallp, const linenr_T lnum_off);
static void checkSmall(win_T *const wp, fold_T *const fp, const linenr_T lnum_off);
static void setSmallMaybe(garray_T *gap);
static void foldCreateMarkers(win_T *wp, pos_T start, pos_T end);
static void foldAddMarker(buf_T *buf, pos_T pos, const char *marker, size_t markerlen);
static void deleteFoldMarkers(win_T *wp, fold_T *fp, int recursive, linenr_T lnum_off);
static void foldDelMarker(buf_T *buf, linenr_T lnum, char *marker, size_t markerlen);
static void foldtext_cleanup(char *str);
static void foldUpdateIEMS(win_T *const wp, linenr_T top, linenr_T bot);
static linenr_T foldUpdateIEMSRecurse(garray_T *const gap, const int level, const linenr_T startlnum, fline_T *const flp, LevelGetter getlevel, linenr_T bot, const char topflags);
static void foldInsert(garray_T *gap, int i);
static void foldSplit(buf_T *buf, garray_T *const gap, const int i, const linenr_T top, const linenr_T bot);
static void foldRemove(win_T *const wp, garray_T *gap, linenr_T top, linenr_T bot);
static void foldReverseOrder(garray_T *gap, const linenr_T start_arg, const linenr_T end_arg);
static void truncate_fold(win_T *const wp, fold_T *fp, linenr_T end);
static void foldMerge(win_T *const wp, fold_T *fp1, garray_T *gap, fold_T *fp2);
static void foldlevelIndent(fline_T *flp);
static void foldlevelDiff(fline_T *flp);
static void foldlevelExpr(fline_T *flp);
static void parseMarker(win_T *wp);
static void foldlevelMarker(fline_T *flp);
static void foldlevelSyntax(fline_T *flp);
static int put_folds_recurse(FILE *fd, garray_T *gap, linenr_T off);
static int put_foldopen_recurse(FILE *fd, win_T *wp, garray_T *gap, linenr_T off);
static int put_fold_open_close(FILE *fd, fold_T *fp, linenr_T off);
static void foldclosed_both(typval_T *argvars, typval_T *rettv, int end);
#include "nvim/func_attr.h"
