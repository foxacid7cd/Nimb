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
DLLEXPORT LexExprToken viml_pexpr_next_token(ParserState *const pstate, const int flags) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
DLLEXPORT const char *viml_pexpr_repr_token(const ParserState *const pstate, const LexExprToken token, size_t *const ret_size) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT void viml_pexpr_free_ast(ExprAST ast);
DLLEXPORT ExprAST viml_pexpr_parse(ParserState *const pstate, const int flags) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
