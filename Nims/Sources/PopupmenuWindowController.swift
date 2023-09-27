// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim

@MainActor
protocol GridWindowFrameTransformer: AnyObject {
  func anchorOrigin(for anchor: Popupmenu.Anchor) -> CGPoint?
}

final class PopupmenuWindowController: NSWindowController {
  private let store: Store
  private let parentWindow: NSWindow
  private weak var gridWindowFrameTransformer: GridWindowFrameTransformer?
  private let viewController: PopupmenuViewController
  private var task: Task<Void, Never>?

  init(store: Store, parentWindow: NSWindow, gridWindowFrameTransformer: GridWindowFrameTransformer) {
    self.store = store
    self.parentWindow = parentWindow
    self.gridWindowFrameTransformer = gridWindowFrameTransformer
    viewController = .init(store: store)

    let window = NSWindow(contentViewController: viewController)
    window.styleMask = [.titled, .fullSizeContentView]
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isMovable = false
    window.isOpaque = false
    window.setIsVisible(false)

    super.init(window: window)

    updateWindow()

    task = Task { [weak self] in
      for await updates in store.stateUpdatesStream() {
        guard let self, !Task.isCancelled else {
          break
        }

        if updates.isPopupmenuUpdated || updates.isAppearanceUpdated || updates.isFontUpdated {
          updateWindow()

        } else if updates.isPopupmenuSelectionUpdated {
          viewController.reloadData()

          if let selectedItemIndex = self.store.popupmenu?.selectedItemIndex {
            viewController.scrollTo(itemAtIndex: selectedItemIndex)
          }
        }
      }
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func updateWindow() {
    if let popupmenu = store.popupmenu {
      viewController.reloadData()

      if let anchorOrigin = gridWindowFrameTransformer?.anchorOrigin(for: popupmenu.anchor) {
        let outerGrid = store.grids[.outer]!
        let upsideDownTransform = CGAffineTransform(scaleX: 1, y: -1)
          .translatedBy(x: 0, y: -Double(outerGrid.cells.size.rowsCount))

        let size = CGSize(
          width: 394,
          height: 176
        )
        let origin = CGPoint(
          x: anchorOrigin.x - 13,
          y: anchorOrigin.y - size.height - store.font.cellHeight
        )
        let gridFrame = CGRect(
          x: floor(origin.x / store.font.cellWidth),
          y: floor(origin.y / store.font.cellHeight),
          width: ceil(size.width / store.font.cellWidth),
          height: ceil(size.height / store.font.cellHeight)
        )
        .applying(upsideDownTransform)

        Task {
          await store.instance.reportPumBounds(gridFrame: gridFrame)
        }

        viewController.preferredContentSize = size
        window!.setFrame(
          CGRect(
            origin: origin + parentWindow.frame.origin,
            size: size
          ),
          display: true
        )
        window!.setFrameOrigin(
          origin.applying(.init(translationX: parentWindow.frame.origin.x, y: parentWindow.frame.origin.y))
        )
        parentWindow.addChildWindow(window!, ordered: .above)

        if let selectedItemIndex = popupmenu.selectedItemIndex {
          viewController.scrollTo(itemAtIndex: selectedItemIndex)
        }
      }

    } else {
      parentWindow.removeChildWindow(window!)
      window!.setIsVisible(false)
    }
  }
}

private final class PopupmenuViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
  func reloadData() {
    tableView.reloadData()
  }

  func scrollTo(itemAtIndex index: Int) {
    tableView.scrollRowToVisible(index)
  }

  private let store: Store
  private let scrollView = NSScrollView()
  private let tableView = NSTableView()

  init(store: Store) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let view = NSView()

    let blurView = NSVisualEffectView()
    blurView.blendingMode = .behindWindow
    blurView.state = .active
    blurView.frame = view.bounds
    blurView.autoresizingMask = [.width, .height]
    view.addSubview(blurView)

    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = .init(top: 5, left: 5, bottom: 5, right: 5)
    scrollView.frame = view.bounds
    scrollView.autoresizingMask = [.width, .height]
    scrollView.drawsBackground = false
    view.addSubview(scrollView)

    tableView.headerView = nil
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .clear
    tableView.addTableColumn(
      .init(identifier: PopupmenuItemView.ReuseIdentifier)
    )
    tableView.rowHeight = 20
    tableView.style = .plain
    tableView.selectionHighlightStyle = .none
    scrollView.documentView = tableView

    self.view = view
  }

  func numberOfRows(in tableView: NSTableView) -> Int {
    store.popupmenu?.items.count ?? 0
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    var itemView = tableView.makeView(withIdentifier: PopupmenuItemView.ReuseIdentifier, owner: self) as? PopupmenuItemView

    if itemView == nil {
      itemView = .init()
      itemView!.identifier = PopupmenuItemView.ReuseIdentifier
    }

    if let popupmenu = store.popupmenu, row < popupmenu.items.count {
      itemView!.set(item: popupmenu.items[row], isSelected: popupmenu.selectedItemIndex == row, font: store.font)
    }
    return itemView
  }

  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    Task {
      await store.instance.reportPopupmenuItemSelected(atIndex: row)
    }

    return false
  }
}

private final class PopupmenuItemView: NSView {
  private let textField = NSTextField(labelWithString: "")
  private let secondTextField = NSTextField(labelWithString: "")
  private var isSelected = false
  private var accentColor = NSColor.white
  private var darkerAccentColor = NSColor.white

  static let ReuseIdentifier = NSUserInterfaceItemIdentifier(.init(describing: PopupmenuItemView.self))

  init() {
    super.init(frame: .zero)

    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    addSubview(textField)

    secondTextField.translatesAutoresizingMaskIntoConstraints = false
    secondTextField.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    secondTextField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    addSubview(secondTextField)

    addConstraints([
      textField.leadingAnchor.constraint(equalTo: leadingAnchor),
      textField.centerYAnchor.constraint(equalTo: centerYAnchor),

      secondTextField.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 4),
      secondTextField.trailingAnchor.constraint(equalTo: trailingAnchor),
      secondTextField.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ dirtyRect: NSRect) {
    let graphicsContext = NSGraphicsContext.current!
    let cgContext = graphicsContext.cgContext

    cgContext.saveGState()

    dirtyRect.clip()

    (isSelected ? darkerAccentColor : .clear)
      .setFill()

    let roundedRectPath = CGPath(
      roundedRect: bounds.insetBy(dx: -8, dy: 0),
      cornerWidth: 5,
      cornerHeight: 5,
      transform: nil
    )
    cgContext.addPath(roundedRectPath)
    cgContext.drawPath(using: .fill)

    cgContext.restoreGState()

    super.draw(dirtyRect)
  }

  func set(item: PopupmenuItem, isSelected: Bool, font: NimsFont) {
    let secondaryText = [item.kind, item.menu, item.info]
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: " ")

    accentColor = NSColor(hueSource: secondaryText, saturation: 0.6, brightness: 0.9)
    darkerAccentColor = accentColor.withAlphaComponent(0.5)

    self.isSelected = isSelected
    needsDisplay = true

    textField.attributedStringValue = .init(string: item.word, attributes: [
      .foregroundColor: NSColor.white,
      .font: font.nsFont(),
    ])

    secondTextField.attributedStringValue = .init(string: secondaryText, attributes: [
      .foregroundColor: isSelected ? NSColor.textColor : accentColor,
      .font: font.nsFont(isItalic: true),
    ])
  }
}
