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
DLLEXPORT void marktree_put(MarkTree *b, mtkey_t key, int end_row, int end_col, _Bool end_right);
DLLEXPORT void marktree_put_key(MarkTree *b, mtkey_t k);
DLLEXPORT void marktree_del_itr(MarkTree *b, MarkTreeIter *itr, _Bool rev);
DLLEXPORT void marktree_clear(MarkTree *b);
DLLEXPORT void marktree_free_node(mtnode_t *x);
DLLEXPORT void marktree_revise(MarkTree *b, MarkTreeIter *itr, uint8_t decor_level, mtkey_t key);
DLLEXPORT void marktree_move(MarkTree *b, MarkTreeIter *itr, int row, int col);
DLLEXPORT _Bool marktree_itr_get(MarkTree *b, int32_t row, int col, MarkTreeIter *itr);
DLLEXPORT _Bool marktree_itr_get_ext(MarkTree *b, mtpos_t p, MarkTreeIter *itr, _Bool last, _Bool gravity, mtpos_t *oldbase);
DLLEXPORT _Bool marktree_itr_first(MarkTree *b, MarkTreeIter *itr);
DLLEXPORT int marktree_itr_last(MarkTree *b, MarkTreeIter *itr);
DLLEXPORT _Bool marktree_itr_next(MarkTree *b, MarkTreeIter *itr);
DLLEXPORT _Bool marktree_itr_prev(MarkTree *b, MarkTreeIter *itr);
DLLEXPORT void marktree_itr_rewind(MarkTree *b, MarkTreeIter *itr);
DLLEXPORT _Bool marktree_itr_node_done(MarkTreeIter *itr);
DLLEXPORT mtpos_t marktree_itr_pos(MarkTreeIter *itr);
DLLEXPORT mtkey_t marktree_itr_current(MarkTreeIter *itr);
DLLEXPORT _Bool marktree_splice(MarkTree *b, int32_t start_line, int start_col, int old_extent_line, int old_extent_col, int new_extent_line, int new_extent_col);
DLLEXPORT void marktree_move_region(MarkTree *b, int start_row, colnr_T start_col, int extent_row, colnr_T extent_col, int new_row, colnr_T new_col);
DLLEXPORT mtkey_t marktree_lookup_ns(MarkTree *b, uint32_t ns, uint32_t id, _Bool end, MarkTreeIter *itr);
DLLEXPORT mtkey_t marktree_lookup(MarkTree *b, uint64_t id, MarkTreeIter *itr);
DLLEXPORT mtpos_t marktree_get_altpos(MarkTree *b, mtkey_t mark, MarkTreeIter *itr);
DLLEXPORT mtkey_t marktree_get_alt(MarkTree *b, mtkey_t mark, MarkTreeIter *itr);
DLLEXPORT void marktree_put_test(MarkTree *b, uint32_t id, int row, int col, _Bool right_gravity);
DLLEXPORT _Bool mt_right_test(mtkey_t key);
DLLEXPORT void marktree_check(MarkTree *b);
DLLEXPORT char *mt_inspect_rec(MarkTree *b);
DLLEXPORT void mt_inspect_node(MarkTree *b, garray_T *ga, mtnode_t *n, mtpos_t off);
#include "nvim/func_attr.h"
