// SPDX-License-Identifier: MIT

import AppKit

@objc(NimbAppearanceChange)
public class AppearanceChange: NSObject, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool {
    true
  }

  public let type: AppearanceChangeType
  public let hlAttrDefineChange: AppearanceHlAttrDefineChange?
  public let defaultColorsSetChange: AppearanceDefaultColorsSetChange?

  public init(
    type: AppearanceChangeType,
    hlAttrDefineChange: AppearanceHlAttrDefineChange? = nil,
    defaultColorsSetChange: AppearanceDefaultColorsSetChange? = nil
  ) {
    self.type = type
    self.hlAttrDefineChange = hlAttrDefineChange
    self.defaultColorsSetChange = defaultColorsSetChange
  }

  public required init?(coder: NSCoder) {
    let rawType = coder.decodeInteger(forKey: "type")
    guard let type = AppearanceChangeType(rawValue: rawType) else {
      return nil
    }
    self.type = type

    switch type {
    case .hlAttrDefine:
      hlAttrDefineChange = coder.decodeObject(of: AppearanceHlAttrDefineChange.self, forKey: "hlAttrDefineChange")
      defaultColorsSetChange = nil

    case .defaultColorsSet:
      hlAttrDefineChange = nil
      defaultColorsSetChange = coder.decodeObject(of: AppearanceDefaultColorsSetChange.self, forKey: "defaultColorsSetChange")
    }
  }

  public func encode(with coder: NSCoder) {
    coder.encode(type.rawValue, forKey: "type")

    switch type {
    case .hlAttrDefine:
      coder.encode(hlAttrDefineChange!, forKey: "hlAttrDefineChange")

    case .defaultColorsSet:
      coder.encode(defaultColorsSetChange!, forKey: "defaultColorsSetChange")
    }
  }
}

public enum AppearanceChangeType: Int {
  case hlAttrDefine
  case defaultColorsSet
}

@objc(NimbAppearanceHlAttrDefineChange)
public class AppearanceHlAttrDefineChange: NSObject, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool {
    true
  }

  public let id: Int
  public let rgbAttrs: [Value: Value]
  public let info: [Value]

  public init(id: Int, rgbAttrs: [Value: Value], info: [Value]) {
    self.id = id
    self.rgbAttrs = rgbAttrs
    self.info = info
  }

  public required init?(coder: NSCoder) {
    id = coder.decodeInteger(forKey: "id")

    guard
      let rawRgbAttrsKeys = coder.decodeObject(of: NSData.self, forKey: "rgbAttrsKeys") as? Data,
      let rawRgbAttrsValues = coder.decodeObject(of: NSData.self, forKey: "rgbAttrsValues") as? Data,
      let rawInfo = coder.decodeObject(of: NSData.self, forKey: "info") as? Data
    else {
      return nil
    }

    let unpacker = Unpacker()
    let unpackedRgbAttrsKeys = rawRgbAttrsKeys.withUnsafeBytes { bufferPointer in
      try? unpacker.unpack(bufferPointer)
    }
    let unpackedRgbAttrsValues = rawRgbAttrsValues.withUnsafeBytes { bufferPointer in
      try? unpacker.unpack(bufferPointer)
    }
    let unpackedInfo = rawInfo.withUnsafeBytes { bufferPointer in
      try? unpacker.unpack(bufferPointer)
    }

    guard
      case let .array(rgbAttrsKeys) = unpackedRgbAttrsKeys?.first,
      case let .array(rgbAttrsValues) = unpackedRgbAttrsValues?.first,
      case let .array(info) = unpackedInfo?.first
    else {
      return nil
    }

    var rgbAttrs = [Value: Value]()
    for (key, value) in zip(rgbAttrsKeys, rgbAttrsValues) {
      rgbAttrs[key] = value
    }
    self.rgbAttrs = rgbAttrs

    self.info = info
  }

  public func encode(with coder: NSCoder) {
    coder.encode(id, forKey: "id")

    var rgbAttrsKeys = [Value]()
    var rgbAttrsValues = [Value]()
    for (key, value) in rgbAttrs {
      rgbAttrsKeys.append(key)
      rgbAttrsValues.append(value)
    }

    let packer = Packer()
    let rawRgbAttrsKeys = packer.pack(.array(rgbAttrsKeys))
    let rawRgbAttrsValues = packer.pack(.array(rgbAttrsValues))
    let rawInfo = packer.pack(.array(info))

    coder.encode(rawRgbAttrsKeys as NSData, forKey: "rgbAttrsKeys")
    coder.encode(rawRgbAttrsValues as NSData, forKey: "rgbAttrsValues")
    coder.encode(rawInfo as NSData, forKey: "info")
  }
}

@objc(NimbAppearanceDefaultColorsSetChange)
public class AppearanceDefaultColorsSetChange: NSObject, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool {
    true
  }

  public let fg: Int
  public let bg: Int
  public let sp: Int

  public init(fg: Int, bg: Int, sp: Int) {
    self.fg = fg
    self.bg = bg
    self.sp = sp
  }

  public required init?(coder: NSCoder) {
    fg = coder.decodeInteger(forKey: "fg")
    bg = coder.decodeInteger(forKey: "bg")
    sp = coder.decodeInteger(forKey: "sp")
  }

  public func encode(with coder: NSCoder) {
    coder.encode(fg, forKey: "fg")
    coder.encode(bg, forKey: "bg")
    coder.encode(sp, forKey: "sp")
  }
}
