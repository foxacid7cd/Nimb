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
DLLEXPORT void hash_init(hashtab_T *ht);
DLLEXPORT void hash_clear(hashtab_T *ht);
DLLEXPORT void hash_clear_all(hashtab_T *ht, unsigned int off);
DLLEXPORT hashitem_T *hash_find(const hashtab_T *const ht, const char *const key);
DLLEXPORT hashitem_T *hash_find_len(const hashtab_T *const ht, const char *const key, const size_t len);
DLLEXPORT hashitem_T *hash_lookup(const hashtab_T *const ht, const char *const key, const size_t key_len, const hash_T hash);
DLLEXPORT void hash_debug_results(void);
DLLEXPORT int hash_add(hashtab_T *ht, char_u *key);
DLLEXPORT void hash_add_item(hashtab_T *ht, hashitem_T *hi, char_u *key, hash_T hash);
DLLEXPORT void hash_remove(hashtab_T *ht, hashitem_T *hi);
DLLEXPORT void hash_lock(hashtab_T *ht);
DLLEXPORT void hash_unlock(hashtab_T *ht);
DLLEXPORT hash_T hash_hash(const char_u *key);
DLLEXPORT hash_T hash_hash_len(const char *key, const size_t len) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT const char_u *_hash_key_removed(void) FUNC_ATTR_PURE FUNC_ATTR_WARN_UNUSED_RESULT;
#include "nvim/func_attr.h"
