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
  case winPos = "win_pos"
  case defaultColorsSet = "default_colors_set"
  case hlAttrDefine = "hl_attr_define"
  case flush
}
