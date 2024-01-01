// SPDX-License-Identifier: MIT

import AppKit
import CasePaths
import Library

public final class PopupmenuViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
  public init(store: Store, getGridView: @escaping (Grid.ID) -> GridView, getCmdlinesView: @escaping () -> NSView) {
    self.store = store
    self.getGridView = getGridView
    self.getCmdlinesView = getCmdlinesView
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var anchorConstraints = [NSLayoutConstraint]()

  public var didShowPopupmenu: (() -> Void)?

  public func render(_ stateUpdates: State.Updates) {
    (view as! FloatingWindowView).render(stateUpdates)

    if let popupmenu = store.state.popupmenu {
      if stateUpdates.isPopupmenuUpdated {
        NSLayoutConstraint.deactivate(anchorConstraints)

        switch popupmenu.anchor {
        case let .grid(id, origin):
          let gridView = getGridView(id)
          let offset = origin * store.font.cellSize
          anchorConstraints = [
            view.leading(to: gridView, offset: offset.x - 13),
            view.top(to: gridView, offset: offset.y + store.font.cellHeight + 2),
            view.width(290),
          ]

        case .cmdline:
          let cmdlinesView = getCmdlinesView()
          anchorConstraints = [
            view.leading(to: cmdlinesView),
            view.trailing(to: cmdlinesView),
            view.topToBottom(of: cmdlinesView, offset: 8),
          ]
        }
      }

      if stateUpdates.isPopupmenuUpdated || stateUpdates.isPopupmenuSelectionUpdated || stateUpdates.isAppearanceUpdated {
        tableView.reloadData()

        if let selectedItemIndex = popupmenu.selectedItemIndex {
          tableView.scrollRowToVisible(selectedItemIndex)
        }
      }
    }

    if stateUpdates.isPopupmenuUpdated {
      let hide = store.state.popupmenu == nil
      let isSuccess = (view as! FloatingWindowView).animate(hide: hide) { [weak self] isCompleted in
        guard let self else {
          return
        }
        if !hide, isCompleted {
          didShowPopupmenu?()
        }
      }
      if !hide, isSuccess {
        scrollView.contentView.scroll(to: .init(
          x: -scrollView.contentInsets.left,
          y: -scrollView.contentInsets.top
        ))
      }
    }
  }

  override public func loadView() {
    let view = FloatingWindowView(store: store, observedHighlightName: .pmenu)
    view.alphaValue = 0
    view.isHidden = true
    view.height(176)

    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = .init(top: 5, left: 5, bottom: 5, right: 5)
    scrollView.drawsBackground = false
    view.addSubview(scrollView)
    scrollView.edgesToSuperview()

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

  public func numberOfRows(in tableView: NSTableView) -> Int {
    store.state.popupmenu?.items.count ?? 0
  }

  public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    var itemView = tableView.makeView(withIdentifier: PopupmenuItemView.ReuseIdentifier, owner: self) as? PopupmenuItemView
    if itemView == nil {
      itemView = .init(store: store)
      itemView!.identifier = PopupmenuItemView.ReuseIdentifier
    }
    if let popupmenu = store.state.popupmenu, row < popupmenu.items.count {
      itemView!.set(
        item: popupmenu.items[row],
        isSelected: popupmenu.selectedItemIndex == row
      )
    }
    return itemView
  }

  public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    Task {
      await store.reportPopupmenuItemSelected(atIndex: row, isFinish: false)
    }
    return false
  }

  private let store: Store
  private let getGridView: (Grid.ID) -> GridView
  private let getCmdlinesView: () -> NSView
  private lazy var scrollView = NSScrollView()
  private lazy var tableView = TableView()
}

private class TableView: NSTableView {
  override var acceptsFirstResponder: Bool {
    false
  }
}
