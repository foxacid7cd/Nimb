// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim

@MainActor
protocol GridWindowFrameTransformer: AnyObject {
  func frame(forGridID gridID: Grid.ID, gridFrame: IntegerRectangle) -> CGRect?
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
    window.styleMask = [.borderless]
    window.isOpaque = false
    window.setIsVisible(false)
    window.alphaValue = 0.95

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

      switch popupmenu.anchor {
      case let .grid(id, origin):
        let originGridFrame = IntegerRectangle(
          origin: origin,
          size: .init(columnsCount: 1, rowsCount: 1)
        )
        guard let originFrame = gridWindowFrameTransformer?.frame(forGridID: id, gridFrame: originGridFrame) else {
          break
        }

        let outerGrid = store.grids[.outer]!
        let upsideDownTransform = CGAffineTransform(scaleX: 1, y: -1)
          .translatedBy(x: 0, y: -Double(outerGrid.cells.size.rowsCount))

        let size = CGSize(
          width: 360,
          height: 160
        )
        let origin = CGPoint(
          x: originFrame.minX,
          y: originFrame.minY - size.height
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
        window!.setFrameOrigin(origin)
        parentWindow.addChildWindow(window!, ordered: .above)

        if let selectedItemIndex = popupmenu.selectedItemIndex {
          viewController.scrollTo(itemAtIndex: selectedItemIndex)
        }

      case .cmdline:
        break
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
    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = .init()

    tableView.headerView = nil
    tableView.delegate = self
    tableView.dataSource = self
    tableView.addTableColumn(
      .init(identifier: PopupmenuItemView.ReuseIdentifier)
    )
    tableView.rowHeight = 20
    tableView.style = .plain
    tableView.selectionHighlightStyle = .none
    scrollView.documentView = tableView

    view = scrollView
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
      itemView!.set(item: popupmenu.items[row], isSelected: popupmenu.selectedItemIndex == row)
    }
    return itemView
  }
}

private final class PopupmenuItemView: NSView {
  private let textField = NSTextField(labelWithString: "")
  private let secondTextField = NSTextField(labelWithString: "")
  private var isSelected = false

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
    let backgroundColor: NSColor = isSelected ? .textColor : .clear
    backgroundColor.setFill()
    dirtyRect.fill()

    super.draw(dirtyRect)
  }

  func set(item: PopupmenuItem, isSelected: Bool) {
    self.isSelected = isSelected
    needsDisplay = true

    textField.attributedStringValue = .init(string: item.word, attributes: [
      .foregroundColor: isSelected ? NSColor.black : NSColor.white,
      .font: NSFont(name: "SFMono Nerd Font Mono", size: 12)!,
    ])
    secondTextField.attributedStringValue = .init(string: item.kind, attributes: [
      .foregroundColor: isSelected ? NSColor.black : NSColor.textColor,
      .font: NSFont(name: "SFMono Nerd Font Mono", size: 11)!,
    ])
  }
}
