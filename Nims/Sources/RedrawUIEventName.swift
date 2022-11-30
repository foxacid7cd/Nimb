//
//  RedrawUIEventName.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Foundation

enum RedrawUIEventName: String {
  case gridResize = "grid_resize"
  case gridLine = "grid_line"
  case gridClear = "grid_clear"
  case gridCursorGoto = "grid_cursor_goto"
  case gridDestroy = "grid_destroy"
  case winPos = "win_pos"
  case winFloatPos = "win_float_pos"
  case winHide = "win_hide"
  case winClose = "win_close"
  case defaultColorsSet = "default_colors_set"
  case hlAttrDefine = "hl_attr_define"
  case flush
}
