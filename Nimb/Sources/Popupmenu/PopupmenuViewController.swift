// SPDX-License-Identifier: MIT

import AppKit
import CasePaths
import Library

public class PopupmenuViewController: NSViewController {
  public init(store: Store, getCmdlinesView: @escaping () -> NSView) {
    self.store = store
    self.getCmdlinesView = getCmdlinesView
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var anchorConstraints = [NSLayoutConstraint]()

  public var willShowPopupmenu: (() -> Void)?

  public func render(_ stateUpdates: State.Updates) {
    if
      stateUpdates.isAppearanceUpdated,
      stateUpdates.updatedObservedHighlightNames.contains(.normalFloat)
    {
      renderCustomView()
    }

    if let popupmenu = store.state.popupmenu {
      if stateUpdates.isPopupmenuUpdated {
        NSLayoutConstraint.deactivate(anchorConstraints)

        switch popupmenu.anchor {
        case let .grid(id, origin):
          break
//          let offset = origin * store.font.cellSize
//          anchorConstraints = [
//            view.leading(to: gridView, offset: offset.x - 13),
//            view.top(to: gridView, offset: offset.y + store.font.cellHeight + 2),
//            view.width(290),
//          ]

        case .cmdline:
          let cmdlinesView = getCmdlinesView()
          anchorConstraints = [
            view.leading(to: cmdlinesView),
            view.trailing(to: cmdlinesView),
            view.topToBottom(of: cmdlinesView, offset: 8),
          ]
        }
      }
      if stateUpdates.isPopupmenuUpdated || stateUpdates.isAppearanceUpdated {
        tableView.reloadData()
        storePreviousSelectedItemIndex(for: popupmenu)
        scrollToSelectedRow(for: popupmenu)
      } else if stateUpdates.isPopupmenuSelectionUpdated {
        scrollToSelectedRow(for: popupmenu)
        if 
          let previousSelectedItemIndex,
          previousSelectedItemIndex < popupmenu.items.count,
          let selectedItemIndex = popupmenu.selectedItemIndex,
          selectedItemIndex < popupmenu.items.count
        {
          tableView.reloadData(forRowIndexes: [previousSelectedItemIndex, selectedItemIndex], columnIndexes: [0])
        } else {
          tableView.reloadData()
        }
        storePreviousSelectedItemIndex(for: popupmenu)
      }
    }

    if stateUpdates.isPopupmenuUpdated {
      let on = store.state.popupmenu != nil
      if on {
        willShowPopupmenu?()
      }
      let isSuccess = customView.toggle(on: on)
      if on, isSuccess {
        scrollView.contentView.scroll(to: .init(
          x: -scrollView.contentInsets.left,
          y: -scrollView.contentInsets.top
        ))
      }
    }

    func storePreviousSelectedItemIndex(for popupmenu: Popupmenu) {
      if let selectedItemIndex = popupmenu.selectedItemIndex {
        previousSelectedItemIndex = selectedItemIndex
      }
    }

    func scrollToSelectedRow(for popupmenu: Popupmenu) {
      if let selectedItemIndex = popupmenu.selectedItemIndex {
        tableView.scrollRowToVisible(selectedItemIndex)
      }
    }
  }

  override public func loadView() {
    let view = customView
    view.height(156)

    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = .init(top: 8, left: 0, bottom: 8, right: 0)
    scrollView.drawsBackground = false
    view.addSubview(scrollView)
    scrollView.edgesToSuperview()

    tableView.headerView = nil
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .clear
    tableView.addTableColumn(
      .init(identifier: PopupmenuItemView.reuseIdentifier)
    )
    tableView.rowHeight = 20
    tableView.style = .fullWidth
    tableView.selectionHighlightStyle = .none
    scrollView.documentView = tableView

    self.view = view
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    customView.toggle(on: false)
    renderCustomView()
  }

  private let store: Store
  private let getCmdlinesView: () -> NSView
  private lazy var customView = FloatingWindowView(store: store)
  private lazy var scrollView = NSScrollView()
  private lazy var tableView = TableView()
  private var previousSelectedItemIndex: Int?

  private func renderCustomView() {
    customView.colors = (
      background: store.appearance.backgroundColor(for: .normalFloat),
      border: store.appearance.foregroundColor(for: .normalFloat)
        .with(alpha: 0.3)
    )
    customView.render()
  }
}

extension PopupmenuViewController: NSTableViewDataSource, NSTableViewDelegate {
  public func numberOfRows(in tableView: NSTableView) -> Int {
    store.state.popupmenu?.items.count ?? 0
  }

  public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    var itemView = tableView.makeView(withIdentifier: PopupmenuItemView.reuseIdentifier, owner: self) as? PopupmenuItemView
    if itemView == nil {
      itemView = .init(store: store)
      itemView!.identifier = PopupmenuItemView.reuseIdentifier
    }
    if let popupmenu = store.state.popupmenu, row < popupmenu.items.count {
      itemView!.item = popupmenu.items[row]
      itemView!.isSelected = popupmenu.selectedItemIndex == row
      itemView!.render()
    }
    return itemView
  }

  public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    store.reportPopupmenuItemSelected(atIndex: row, isFinish: false)
    return false
  }
}

private class TableView: NSTableView {
  override var acceptsFirstResponder: Bool {
    false
  }
}