//
//  File.swift
//  
//
//  Created by Yevhenii Matviienko on 28.02.2023.
//

import Collections
import Library
import Tagged
import MessagePack

public struct InstanceState: Sendable {
  public var bufferedUIEvents: [UIEvent]
  public var rawOptions: OrderedDictionary<String, Value>
  public var title: String?
  public var highlights: IntKeyedDictionary<Highlight>
  public var defaultForegroundColor: Neovim.Color?
  public var defaultBackgroundColor: Neovim.Color?
  public var defaultSpecialColor: Neovim.Color?
  public var modeInfo: ModeInfo?
  public var mode: Mode?
  public var cursor: Cursor?
  public var grids: IntKeyedDictionary<Neovim.Grid>
  public var tabline: Tabline?
  public var cmdlines: IntKeyedDictionary<Cmdline>
}
