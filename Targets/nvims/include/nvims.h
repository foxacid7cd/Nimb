//
//  nvims.h
//  Nims
//
//  Created by Yevhenii Matviienko on 11.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#ifndef nvims_h
#define nvims_h

#include <stdio.h>

#define MAX_MCO 6
typedef char nvim_schar_t[(MAX_MCO + 1) * 4 + 1];

typedef int nvim_sattr_t;

struct nvim_string {
  char *data;
  size_t size;
};
typedef struct nvim_string nvim_string_t;

typedef int64_t nvim_handle_t;

typedef int64_t nvim_lua_ref_t;

typedef int32_t nvim_rgb_value_t;

struct nvim_array {
  size_t size;
  size_t capacity;
  struct nvim_object *items;
};
typedef struct nvim_array nvim_array_t;

struct nvim_key_value_pair {
  struct nvim_string key;
  struct nvim_object *value;
};
typedef struct nvim_key_value_pair nvim_key_value_pair_t;

struct nvim_dictionary {
  size_t size;
  size_t capacity;
  struct nvim_key_value_pair *items;
};
typedef struct nvim_dictionary nvim_dictionary_t;

enum nvim_object_type {
  NvimObjectTypeNil = 0,
  NvimObjectTypeBoolean,
  NvimObjectTypeInteger,
  NvimObjectTypeFloat,
  NvimObjectTypeString,
  NvimObjectTypeArray,
  NvimObjectTypeDictionary,
  NvimObjectTypeLuaRef,
  NvimObjectTypeBuffer,
  NvimObjectTypeWindow,
  NvimObjectTypeTabpage,
};
typedef enum nvim_object_type nvim_object_type_t;

struct nvim_object {
  enum nvim_object_type type;
  union {
    _Bool boolean;
    int64_t integer;
    double floating;
    struct nvim_string string;
    struct nvim_array array;
    struct nvim_dictionary dictionary;
    nvim_lua_ref_t luaref;
  } data;
};
typedef struct nvim_object nvim_object_t;

typedef enum : int16_t {
  NvimHlAttrFlagsInverse = 0x01,
  NvimHlAttrFlagsBold = 0x02,
  NvimHlAttrFlagsItalic = 0x04,
  NvimHlAttrFlagsUnderline = 0x08,
  NvimHlAttrFlagsUndercurl = 0x10,
  NvimHlAttrFlagsUnderdouble = 0x20,
  NvimHlAttrFlagsUnderdotted = 0x40,
  NvimHlAttrFlagsUnderdashed = 0x80,
  NvimHlAttrFlagsStandout = 0x0100,
  NvimHlAttrFlagsNoCombine = 0x0200,
  NvimHlAttrFlagsStrikethrough = 0x0400,
  NvimHlAttrFlagsBgIndexed = 0x0800,
  NvimHlAttrFlagsFgIndexed = 0x1000,
  NvimHlAttrFlagsDefault = 0x2000,
  NvimHlAttrFlagsGlobal = 0x4000,
  NvimHlAttrFlagsAnyUnderline = NvimHlAttrFlagsUnderline | NvimHlAttrFlagsUnderdouble | NvimHlAttrFlagsUndercurl | NvimHlAttrFlagsUnderdotted | NvimHlAttrFlagsUnderdashed,
} nvim_hl_attr_flags_t;

typedef struct {
  nvim_hl_attr_flags_t rgb_ae_attr, cterm_ae_attr;
  nvim_rgb_value_t rgb_fg_color, rgb_bg_color, rgb_sp_color;
  int cterm_fg_color, cterm_bg_color;
  int hl_blend;
} nvim_hl_attrs_t;

typedef struct {
  int width;
  int height;
  void (^mode_info_set)(_Bool enabled, nvim_array_t cursor_styles);
  void (^update_menu)(void);
  void (^busy_start)(void);
  void (^busy_stop)(void);
  void (^mouse_on)(void);
  void (^mouse_off)(void);
  void (^mode_change)(nvim_string_t mode, int64_t mode_idx);
  void (^bell)(void);
  void (^visual_bell)(void);
  void (^flush)(void);
  void (^suspend)(void);
  void (^set_title)(nvim_string_t title);
  void (^set_icon)(nvim_string_t icon);
  void (^screenshot)(nvim_string_t path);
  void (^option_set)(nvim_string_t name, nvim_object_t value);
  void (^stop)(void);
  void (^default_colors_set)(int64_t rgb_fg, int64_t rgb_bg, int64_t rgb_sp, int64_t cterm_fg, int64_t cterm_bg);
  void (^hl_attr_define)(int64_t _id, nvim_hl_attrs_t rgb_attrs, nvim_hl_attrs_t cterm_attrs, nvim_array_t info);
  void (^hl_group_set)(nvim_string_t name, int64_t _id);
  void (^grid_resize)(int64_t grid, int64_t width, int64_t height);
  void (^grid_clear)(int64_t grid);
  void (^grid_cursor_goto)(int64_t grid, int64_t row, int64_t col);
  void (^grid_scroll)(int64_t grid, int64_t top, int64_t bot, int64_t left, int64_t right, int64_t rows, int64_t cols);
  void (^raw_line)(int64_t grid, int64_t row, int64_t startcol, int64_t endcol, int64_t clearcol, int64_t clearattr, int64_t flags, const nvim_schar_t *chunk, const nvim_sattr_t *attrs);
  void (^event)(char *name, nvim_array_t args);
  void (^msg_set_pos)(int64_t grid, int64_t row, _Bool scrolled, nvim_string_t sep_char);
  void (^win_viewport)(int64_t grid, nvim_handle_t win, int64_t topline, int64_t botline, int64_t curline, int64_t curcol, int64_t line_count);
  void (^wildmenu_show)(nvim_array_t items);
  void (^wildmenu_select)(int64_t selected);
  void (^wildmenu_hide)(void);
} nvims_ui_t;

void nvims_start(nvims_ui_t nvims_ui);
int64_t nvims_input(nvim_string_t keys);
void nvims_input_mouse(nvim_string_t button, nvim_string_t action, nvim_string_t modifier, int64_t grid, int64_t row, int64_t col);

typedef struct {
  char data[sizeof(nvim_schar_t) + 1];
  nvim_sattr_t attr;
} nvim_grid_cell_t;

#endif /* nvims_h */
