// SPDX-License-Identifier: MIT

import AppKit
import Carbon
import Library

@PublicInit
public struct KeyPress: Sendable {
  public init(
    event: NSEvent
  ) {
    self.init(
      keyCode: Int(event.keyCode),
      characters: event.charactersIgnoringModifiers?.lowercased() ?? "",
      modifierFlags: event.modifierFlags
    )
  }

  public var keyCode: Int
  public var characters: String
  public var modifierFlags: NSEvent.ModifierFlags

  public var isEscape: Bool {
    keyCode == kVK_Escape
  }

  public func makeNvimKeyCode() -> String {
    guard let unicodeScalar = characters.unicodeScalars.first else {
      return characters
    }
    let specialKey: String? =
      if keyCode == kVK_Escape {
        "Esc"
      } else {
        specialKeys[Int(unicodeScalar.value)]
      }
    let modifiers = modifierFlags.makeModifiers(isSpecialKey: specialKey != nil)
    if !modifiers.isEmpty, let specialKey {
      return "<\((modifiers + [specialKey]).joined(separator: "-"))>"
    } else if !modifiers.isEmpty {
      return "<\((modifiers + [String(unicodeScalar)]).joined(separator: "-"))>"
    } else if let specialKey {
      return "<\(specialKey)>"
    } else {
      var string = String(unicodeScalar)
      if modifierFlags.contains(.shift) {
        string = string.uppercased()
      }
      return string.replacingOccurrences(of: "<", with: "<lt>")
    }
  }
}

public extension NSEvent.ModifierFlags {
  func makeModifiers(isSpecialKey: Bool) -> [String] {
    var accumulator = [String]()
    if contains(.shift), isSpecialKey {
      accumulator.append("S")
    }
    if contains(.control) {
      accumulator.append("C")
    }
    if contains(.option) {
      accumulator.append("M")
    }
    if contains(.command) {
      accumulator.append("D")
    }
    return accumulator
  }
}

private let specialKeys = [
  NSEnterCharacter: "CR", NSDeleteCharacter: "BS", NSBackspaceCharacter: "BS",
  NSDeleteCharFunctionKey: "Del", NSTabCharacter: "Tab",
  NSBackTabCharacter: "Tab",
  NSCarriageReturnCharacter: "CR",
  NSUpArrowFunctionKey: "Up", NSDownArrowFunctionKey: "Down",
  NSLeftArrowFunctionKey: "Left",
  NSRightArrowFunctionKey: "Right", NSInsertFunctionKey: "Insert",
  NSHomeFunctionKey: "Home",
  NSBeginFunctionKey: "Begin", NSEndFunctionKey: "End",
  NSPageUpFunctionKey: "PageUp",
  NSPageDownFunctionKey: "PageDown", NSHelpFunctionKey: "Help",
  NSF1FunctionKey: "F1",
  NSF2FunctionKey: "F2", NSF3FunctionKey: "F3", NSF4FunctionKey: "F4",
  NSF5FunctionKey: "F5",
  NSF6FunctionKey: "F6", NSF7FunctionKey: "F7", NSF8FunctionKey: "F8",
  NSF9FunctionKey: "F9",
  NSF10FunctionKey: "F10", NSF11FunctionKey: "F11", NSF12FunctionKey: "F12",
  NSF13FunctionKey: "F13", NSF14FunctionKey: "F14", NSF15FunctionKey: "F15",
  NSF16FunctionKey: "F16", NSF17FunctionKey: "F17", NSF18FunctionKey: "F18",
  NSF19FunctionKey: "F19", NSF20FunctionKey: "F20", NSF21FunctionKey: "F21",
  NSF22FunctionKey: "F22", NSF23FunctionKey: "F23", NSF24FunctionKey: "F24",
  NSF25FunctionKey: "F25", NSF26FunctionKey: "F26", NSF27FunctionKey: "F27",
  NSF28FunctionKey: "F28", NSF29FunctionKey: "F29", NSF30FunctionKey: "F30",
  NSF31FunctionKey: "F31", NSF32FunctionKey: "F32", NSF33FunctionKey: "F33",
  NSF34FunctionKey: "F34", NSF35FunctionKey: "F35",
  Int(Character(" ").utf16.first!): "Space",
  Int(Character("\\").utf16.first!): "Bslash",
]
