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
    viewController = .init()

    let window = NSWindow(contentViewController: viewController)
    window.styleMask = []
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

        if updates.isPopupmenuUpdated {
          updateWindow()

        } else if
          let popupmenu = store.popupmenu,
          case let .grid(anchorGridID, _) = popupmenu.anchor,
          updates.updatedLayoutGridIDs.contains(anchorGridID)
        {
          updateWindow()

        } else if updates.isFontUpdated {
          updateWindow()
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
      viewController.popupmenu = popupmenu

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
          width: 40 * store.font.cellWidth,
          height: 14 * store.font.cellHeight
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
  var popupmenu: Popupmenu? {
    didSet {
      tableView.reloadData()

      if let selectedItemIndex = popupmenu?.selectedItemIndex {
        tableView.selectRowIndexes([selectedItemIndex], byExtendingSelection: false)
        tableView.scrollRowToVisible(selectedItemIndex)
      }
    }
  }

  private let tableView = NSTableView()

  override func loadView() {
    let scrollView = NSScrollView()
    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = .init()

    tableView.headerView = nil
    tableView.delegate = self
    tableView.dataSource = self
    tableView.addTableColumn(
      .init(identifier: PopupmenuItemView.ReuseIdentifier)
    )
    tableView.style = .fullWidth
    scrollView.documentView = tableView

    view = scrollView
  }

  func numberOfRows(in tableView: NSTableView) -> Int {
    popupmenu?.items.count ?? 0
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    var itemView = tableView.makeView(withIdentifier: PopupmenuItemView.ReuseIdentifier, owner: self) as? PopupmenuItemView

    if itemView == nil {
      itemView = .init()
      itemView!.identifier = PopupmenuItemView.ReuseIdentifier
    }

    itemView!.set(item: popupmenu!.items[row], isSelected: tableView.isRowSelected(row))
    return itemView
  }

  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    false
  }
}

private final class PopupmenuItemView: NSView {
  private let textField = NSTextField(labelWithString: "")
  private let secondTextField = NSTextField(labelWithString: "")

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

  func set(item: PopupmenuItem, isSelected: Bool) {
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
