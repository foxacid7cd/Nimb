//
//  KeyPress.swift
//  Nvim
//
//  Created by Yevhenii Matviienko on 23.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Carbon

public struct KeyPress {
  public init(event: NSEvent) {
    self.keyCode = Int(event.keyCode)
    self.characters = event.charactersIgnoringModifiers?.lowercased() ?? ""
    self.modifierFlags = event.modifierFlags
  }

  var keyCode: Int
  var characters: String
  var modifierFlags: NSEvent.ModifierFlags

  func makeNvimKeyCode() -> String {
    let specialKey: String? = {
      if self.keyCode == kVK_Escape {
        return "Esc"

      } else {
        return self.characters.utf16.first.flatMap { SpecialKeys[Int($0)] }
      }
    }()
    let modifier = self.modifierFlags.modifier

    let components = [modifier, specialKey ?? self.characters]
      .compactMap { $0 }

    if components.count > 1 {
      return "<\(components.joined(separator: "-"))>"

    } else {
      return self.characters
        .replacingOccurrences(of: "<", with: "<lt>")
    }
  }
}

private extension NSEvent.ModifierFlags {
  var modifier: String? {
    if self.contains(.shift) {
      return "S"

    } else if self.contains(.control) {
      return "C"

    } else if self.contains(.option) {
      return "M"

    } else if self.contains(.command) {
      return "D"

    } else {
      return nil
    }
  }
}

private let SpecialKeys = [
  NSEnterCharacter: "CR",
  NSDeleteCharacter: "BS",
  NSBackspaceCharacter: "BS",
  NSDeleteCharFunctionKey: "Del",
  NSTabCharacter: "Tab",
  NSCarriageReturnCharacter: "CR",
  NSUpArrowFunctionKey: "Up",
  NSDownArrowFunctionKey: "Down",
  NSLeftArrowFunctionKey: "Left",
  NSRightArrowFunctionKey: "Right",
  NSInsertFunctionKey: "Insert",
  NSHomeFunctionKey: "Home",
  NSBeginFunctionKey: "Begin",
  NSEndFunctionKey: "End",
  NSPageUpFunctionKey: "PageUp",
  NSPageDownFunctionKey: "PageDown",
  NSHelpFunctionKey: "Help",
  NSF1FunctionKey: "F1",
  NSF2FunctionKey: "F2",
  NSF3FunctionKey: "F3",
  NSF4FunctionKey: "F4",
  NSF5FunctionKey: "F5",
  NSF6FunctionKey: "F6",
  NSF7FunctionKey: "F7",
  NSF8FunctionKey: "F8",
  NSF9FunctionKey: "F9",
  NSF10FunctionKey: "F10",
  NSF11FunctionKey: "F11",
  NSF12FunctionKey: "F12",
  NSF13FunctionKey: "F13",
  NSF14FunctionKey: "F14",
  NSF15FunctionKey: "F15",
  NSF16FunctionKey: "F16",
  NSF17FunctionKey: "F17",
  NSF18FunctionKey: "F18",
  NSF19FunctionKey: "F19",
  NSF20FunctionKey: "F20",
  NSF21FunctionKey: "F21",
  NSF22FunctionKey: "F22",
  NSF23FunctionKey: "F23",
  NSF24FunctionKey: "F24",
  NSF25FunctionKey: "F25",
  NSF26FunctionKey: "F26",
  NSF27FunctionKey: "F27",
  NSF28FunctionKey: "F28",
  NSF29FunctionKey: "F29",
  NSF30FunctionKey: "F30",
  NSF31FunctionKey: "F31",
  NSF32FunctionKey: "F32",
  NSF33FunctionKey: "F33",
  NSF34FunctionKey: "F34",
  NSF35FunctionKey: "F35",
  Int(Character(" ").utf16.first!): "Space",
  Int(Character("\\").utf16.first!): "Bslash"
]
