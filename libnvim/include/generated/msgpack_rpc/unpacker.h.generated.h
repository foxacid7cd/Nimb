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
DLLEXPORT Object unpack(const char *data, size_t size, Error *err);
DLLEXPORT void unpacker_init(Unpacker *p);
DLLEXPORT void unpacker_teardown(Unpacker *p);
DLLEXPORT _Bool unpacker_parse_header(Unpacker *p);
DLLEXPORT _Bool unpacker_advance(Unpacker *p);
DLLEXPORT _Bool unpacker_parse_redraw(Unpacker *p);
#include "nvim/func_attr.h"
