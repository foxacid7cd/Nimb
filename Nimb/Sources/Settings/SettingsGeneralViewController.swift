// SPDX-License-Identifier: MIT

import AppKit
import NimbNeovim
import NimbState

final class SettingsGeneralViewController: NSViewController, Rendering {
  var renderContext: RenderContext! = nil

  private let store: Store
  private let fontValue = NSTextField(labelWithString: "")
  private lazy var chooseFontButton = NSButton(
    title: "Choose…",
    target: self,
    action: #selector(chooseFont),
  )
  private lazy var resetFontButton = NSButton(
    title: "Reset",
    target: self,
    action: #selector(resetFont),
  )
  private lazy var rendererPopUp = NSPopUpButton(
    title: "",
    target: self,
    action: #selector(rendererChanged),
  )

  init(store: Store) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let view = NSView(frame: .init(x: 0, y: 0, width: 520, height: 350))

    fontValue.lineBreakMode = .byTruncatingMiddle
    fontValue.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    let fontControls = NSStackView(views: [fontValue, chooseFontButton, resetFontButton])
    fontControls.orientation = .horizontal
    fontControls.spacing = 8

    rendererPopUp.addItems(withTitles: ["Metal", "Core Graphics"])
    rendererPopUp.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    let grid = NSGridView(views: [
      [label("Editor font"), fontControls],
      [label("Renderer"), rendererPopUp],
    ])
    grid.rowSpacing = 14
    grid.columnSpacing = 16
    grid.column(at: 0).xPlacement = .trailing
    grid.column(at: 1).xPlacement = .fill

    let note =
      NSTextField(
        wrappingLabelWithString: "Font changes update Neovim's 'guifont' option for this session; add it to vimrc to persist it. Metal is recommended; Core Graphics is useful for troubleshooting rendering differences.",
      )
    note.textColor = .secondaryLabelColor

    let stack = NSStackView(views: [grid, note])
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 18
    view.addSubview(stack)
    stack.edgesToSuperview(insets: .init(top: 24, left: 24, bottom: 24, right: 24))
    grid.width(to: stack)
    note.width(to: stack)

    self.view = view
  }

  func render() {
    let font = state.font.appKit()
    let name = (font.displayName ?? font.fontName).trimmingCharacters(in: .whitespacesAndNewlines)
    fontValue.stringValue = "\(name), \(font.pointSize.formatted()) pt"
    rendererPopUp.selectItem(at: state.debug.isCoreGraphicsRenderingEnabled ? 1 : 0)
  }

  @objc private func chooseFont() {
    let manager = NSFontManager.shared
    manager.target = self
    manager.setSelectedFont(state.font.appKit(), isMultiple: false)
    manager.orderFrontFontPanel(nil)
  }

  @objc private func resetFont() {
    setGuifont(Font(NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)))
  }

  @objc private func rendererChanged() {
    let wantsCoreGraphics = rendererPopUp.indexOfSelectedItem == 1
    if wantsCoreGraphics != state.debug.isCoreGraphicsRenderingEnabled {
      store.dispatch(Actions.ToggleCoreGraphicsRendering())
    }
  }

  private func label(_ title: String) -> NSTextField {
    let field = NSTextField(labelWithString: title)
    field.alignment = .right
    return field
  }

  private func setGuifont(_ font: Font) {
    store.api.fastCall(APIFunctions.NvimSetOptionValue(
      name: "guifont",
      value: .string(font.guifontEntry),
      opts: [:],
    ))
  }
}

extension SettingsGeneralViewController: NSFontChanging {
  func changeFont(_ sender: NSFontManager?) {
    guard let sender else {
      return
    }
    setGuifont(Font(sender.convert(state.font.appKit())))
  }
}
