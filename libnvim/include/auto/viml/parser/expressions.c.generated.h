#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static inline float_T scale_number(const float_T num, const uint8_t base, const uvarnumber_T exponent, const _Bool exponent_negative) FUNC_ATTR_ALWAYS_INLINE FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_CONST;
static const char *intchar2str(const int ch) FUNC_ATTR_WARN_UNUSED_RESULT;
static inline ExprASTNode *viml_pexpr_new_node(const ExprASTNodeType type) FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_MALLOC;
static inline ExprOpLvl node_lvl(const ExprASTNode node) FUNC_ATTR_ALWAYS_INLINE FUNC_ATTR_CONST FUNC_ATTR_WARN_UNUSED_RESULT;
static inline ExprOpAssociativity node_ass(const ExprASTNode node) FUNC_ATTR_ALWAYS_INLINE FUNC_ATTR_CONST FUNC_ATTR_WARN_UNUSED_RESULT;
static _Bool viml_pexpr_handle_bop(const ParserState *const pstate, ExprASTStack *const ast_stack, ExprASTNode *const bop_node, ExprASTWantedNode *const want_node_p, ExprASTError *const ast_err) FUNC_ATTR_NONNULL_ALL;
static inline ParserPosition shifted_pos(const ParserPosition pos, const size_t shift) FUNC_ATTR_CONST FUNC_ATTR_ALWAYS_INLINE FUNC_ATTR_WARN_UNUSED_RESULT;
static inline ParserPosition recol_pos(const ParserPosition pos, const size_t new_col) FUNC_ATTR_CONST FUNC_ATTR_ALWAYS_INLINE FUNC_ATTR_WARN_UNUSED_RESULT;
static inline void east_set_error(const ParserState *const pstate, ExprASTError *const ret_ast_err, const char *const msg, const ParserPosition start) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_ALWAYS_INLINE;
static inline _Bool pt_is_assignment(const ExprASTParseType pt) FUNC_ATTR_ALWAYS_INLINE FUNC_ATTR_CONST FUNC_ATTR_WARN_UNUSED_RESULT;
static void parse_quoted_string(ParserState *const pstate, ExprASTNode *const node, const LexExprToken token, const ExprASTStack *ast_stack, const _Bool is_invalid) FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
