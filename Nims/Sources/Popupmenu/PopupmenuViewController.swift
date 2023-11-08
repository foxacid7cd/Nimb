// SPDX-License-Identifier: MIT

import AppKit
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

  public func setIsUserInteractionEnabled(_ value: Bool) {
    customView.isUserInteractionEnabled = value
  }

  public func render(_ stateUpdates: State.Updates) {
    if let popupmenu = store.state.popupmenu {
      if stateUpdates.isPopupmenuUpdated {
        NSLayoutConstraint.deactivate(anchorConstraints)
        switch popupmenu.anchor {
        case let .grid(id, origin):
          let gridView = getGridView(id)
          let offset = origin * store.font.cellSize
          anchorConstraints = [
            view.leading(to: gridView, offset: offset.x),
            view.top(to: gridView, offset: offset.y + store.font.cellHeight),
            view.width(300),
          ]

        case .cmdline:
          let cmdlinesView = getCmdlinesView()
          anchorConstraints = [
            view.leading(to: cmdlinesView),
            view.trailing(to: cmdlinesView),
            view.topToBottom(of: cmdlinesView, offset: 8),
          ]
        }

        if isVisibleAnimatedOn != true {
          scrollView.contentView.scroll(to: .init(
            x: -scrollView.contentInsets.left,
            y: -scrollView.contentInsets.top
          ))

          NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            view.animator().alphaValue = 1
          }
          isVisibleAnimatedOn = true
        }
      }
      if stateUpdates.isPopupmenuUpdated || stateUpdates.isPopupmenuSelectionUpdated {
        tableView.reloadData()

        if let selectedItemIndex = popupmenu.selectedItemIndex {
          tableView.selectRowIndexes([selectedItemIndex], byExtendingSelection: false)
          tableView.scrollRowToVisible(selectedItemIndex)
        }
      }
    } else {
      if isVisibleAnimatedOn != false {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.12
          view.animator().alphaValue = 0
        }
        isVisibleAnimatedOn = false
      }
    }
  }

  override public func loadView() {
    let view = customView
    view.alphaValue = 0
    view.height(176)

    let blurView = NSVisualEffectView()
    blurView.blendingMode = .behindWindow
    blurView.state = .active
    blurView.frame = view.bounds
    blurView.autoresizingMask = [.width, .height]
    view.addSubview(blurView)

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
      itemView = .init()
      itemView!.identifier = PopupmenuItemView.ReuseIdentifier
    }
    if let popupmenu = store.state.popupmenu, row < popupmenu.items.count {
      itemView!.set(item: popupmenu.items[row], isSelected: tableView.isRowSelected(row), font: store.font)
    }
    return itemView
  }

  public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    guard reportPopupmenuItemSelectedTask == nil else {
      return false
    }
    reportPopupmenuItemSelectedTask = Task {
      await store.reportPopupmenuItemSelected(atIndex: row)
      reportPopupmenuItemSelectedTask = nil
    }
    return true
  }

  private let store: Store
  private let getGridView: (Grid.ID) -> GridView
  private let getCmdlinesView: () -> NSView
  private lazy var customView = CustomView()
  private lazy var scrollView = NSScrollView()
  private lazy var tableView = NSTableView()
  private var isVisibleAnimatedOn: Bool?
  private var reportPopupmenuItemSelectedTask: Task<Void, Never>?
}
