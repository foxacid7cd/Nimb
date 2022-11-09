#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static _Bool pos_leq(mtpos_t a, mtpos_t b);
static void relative(mtpos_t base, mtpos_t *val);
static void unrelative(mtpos_t base, mtpos_t *val);
static void compose(mtpos_t *base, mtpos_t val);
static int key_cmp(mtkey_t a, mtkey_t b);
static inline int marktree_getp_aux(const mtnode_t *x, mtkey_t k, int *r);
static inline void refkey(MarkTree *b, mtnode_t *x, int i);
static inline void split_node(MarkTree *b, mtnode_t *x, const int i);
static inline void marktree_putp_aux(MarkTree *b, mtnode_t *x, mtkey_t k);
static mtnode_t *merge_node(MarkTree *b, mtnode_t *p, int i);
static void pivot_right(MarkTree *b, mtnode_t *p, int i);
static void pivot_left(MarkTree *b, mtnode_t *p, int i);
static _Bool marktree_itr_next_skip(MarkTree *b, MarkTreeIter *itr, _Bool skip, mtpos_t oldbase[]);
static _Bool itr_eq(MarkTreeIter *itr1, MarkTreeIter *itr2);
static void itr_swap(MarkTreeIter *itr1, MarkTreeIter *itr2);
static void marktree_itr_fix_pos(MarkTree *b, MarkTreeIter *itr);
static size_t check_node(MarkTree *b, mtnode_t *x, mtpos_t *last, _Bool *last_right);
#include "nvim/func_attr.h"
