// SPDX-License-Identifier: MIT

import CasePaths

@MainActor
public final class RendererGlobalState {
  public var appearance = Appearance()

  public func handle(
    appearanceChange: AppearanceChange,
    _ cb: @Sendable @escaping () -> Void
  ) {
    switch appearanceChange.type {
    case .hlAttrDefine:
      let hlAttrDefine = appearanceChange.hlAttrDefineChange!
      let id = hlAttrDefine.id
      let rawInfo = hlAttrDefine.info
      let rgbAttrs = hlAttrDefine.rgbAttrs

      let noCombine = rgbAttrs["noCombine"]
        .flatMap { $0[case: \.boolean] } ?? false

      var highlight = (
        noCombine ? appearance
          .highlights[id] : nil
      ) ?? .init(id: id)

      for (key, value) in rgbAttrs {
        guard case let .string(key) = key else {
          continue
        }

        switch key {
        case "foreground":
          if case let .integer(value) = value {
            highlight.foregroundColor = .init(rgb: value)
          }

        case "background":
          if case let .integer(value) = value {
            highlight.backgroundColor = .init(rgb: value)
          }

        case "special":
          if case let .integer(value) = value {
            highlight.specialColor = .init(rgb: value)
          }

        case "reverse":
          if case let .boolean(value) = value {
            highlight.isReverse = value
          }

        case "italic":
          if case let .boolean(value) = value {
            highlight.isItalic = value
          }

        case "bold":
          if case let .boolean(value) = value {
            highlight.isBold = value
          }

        case "strikethrough":
          if case let .boolean(value) = value {
            highlight.decorations.isStrikethrough = value
          }

        case "underline":
          if case let .boolean(value) = value {
            highlight.decorations.isUnderline = value
          }

        case "undercurl":
          if case let .boolean(value) = value {
            highlight.decorations.isUndercurl = value
          }

        case "underdouble":
          if case let .boolean(value) = value {
            highlight.decorations.isUnderdouble = value
          }

        case "underdotted":
          if case let .boolean(value) = value {
            highlight.decorations.isUnderdotted = value
          }

        case "underdashed":
          if case let .boolean(value) = value {
            highlight.decorations.isUnderdashed = value
          }

        case "blend":
          if case let .integer(value) = value {
            highlight.blend = value
          }

        case "bg_indexed",
             "fg_indexed",
             "nocombine",
             "standout",
             "url":
          continue

        default:
          logger.error("Unknown hl attr define rgb attr key \(key)")
        }
      }

      appearance.highlights[id] = highlight

    case .defaultColorsSet:
      let defaultColorsSet = appearanceChange.defaultColorsSetChange!

      let foreground = Color(rgb: defaultColorsSet.fg)
      let background = Color(rgb: defaultColorsSet.bg)
      let special = Color(rgb: defaultColorsSet.sp)
      appearance
        .defaultForegroundColor = foreground
      appearance
        .defaultBackgroundColor = background
      appearance.defaultSpecialColor = special
    }

    cb()
  }
}
