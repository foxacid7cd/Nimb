// SPDX-License-Identifier: MIT

import AppKit
import CasePaths
import Library

public final class PopupmenuViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
  public init(store: Store, getGridsView: @escaping () -> GridsView, getGridView: @escaping (Grid.ID) -> GridView, getCmdlinesView: @escaping () -> NSView) {
    self.store = store
    self.getGridsView = getGridsView
    self.getGridView = getGridView
    self.getCmdlinesView = getCmdlinesView
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var anchorConstraints = [NSLayoutConstraint]()

  override public func viewDidLayout() {
    super.viewDidLayout()

    reportPumBounds()
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

        if isVisibleAnimatedOn != true {
          isVisibleAnimatedOn = true
          scrollView.contentView.scroll(to: .init(
            x: -scrollView.contentInsets.left,
            y: -scrollView.contentInsets.top
          ))
          view.isHidden = false
          NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            view.animator().alphaValue = 1
          } completionHandler: { [weak self] in
            guard let self else {
              return
            }
            if isVisibleAnimatedOn == true {
              reportPumBounds()
            }
          }
        }
      }
      if stateUpdates.isPopupmenuUpdated || stateUpdates.isPopupmenuSelectionUpdated {
        tableView.reloadData()

        if let selectedItemIndex = popupmenu.selectedItemIndex {
          tableView.scrollRowToVisible(selectedItemIndex)
        }
      }
    } else {
      if isVisibleAnimatedOn != false {
        isVisibleAnimatedOn = false
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.12
          view.animator().alphaValue = 0
        } completionHandler: { [weak self] in
          guard let self else {
            return
          }
          if isVisibleAnimatedOn == false {
            view.isHidden = true
          }
        }
      }
    }
  }

  override public func loadView() {
    let view = NSView()
    view.wantsLayer = true
    view.shadow = .init()
    view.layer!.cornerRadius = 8
    view.layer!.borderColor = NSColor.textColor.withAlphaComponent(0.2).cgColor
    view.layer!.borderWidth = 1
    view.layer!.shadowRadius = 5
    view.layer!.shadowOffset = .init(width: 4, height: -4)
    view.layer!.shadowOpacity = 0.2
    view.layer!.shadowColor = .black
    view.alphaValue = 0
    view.isHidden = true
    view.height(176)

    let blurView = NSVisualEffectView()
    blurView.wantsLayer = true
    blurView.layer!.masksToBounds = true
    blurView.layer!.cornerRadius = 8
    blurView.blendingMode = .withinWindow
    blurView.material = .popover
    view.addSubview(blurView)
    blurView.edgesToSuperview()

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
  private let getGridsView: () -> GridsView
  private let getGridView: (Grid.ID) -> GridView
  private let getCmdlinesView: () -> NSView
  private lazy var scrollView = NSScrollView()
  private lazy var tableView = TableView()
  private var isVisibleAnimatedOn: Bool?

  private func reportPumBounds() {
    guard let outerGrid = store.state.outerGrid else {
      return
    }
    let gridsView = getGridsView()
    let viewFrame = gridsView.convert(view.frame, from: nil)
    let size = IntegerSize(
      columnsCount: Int((viewFrame.size.width / store.font.cellWidth).rounded(.down)),
      rowsCount: Int((viewFrame.size.height / store.font.cellHeight).rounded(.down))
    )
    let rectangle = IntegerRectangle(
      origin: .init(
        column: Int((viewFrame.origin.x / store.font.cellWidth).rounded(.up)),
        row: outerGrid.rowsCount - Int((viewFrame.origin.y / store.font.cellHeight).rounded(.up)) - size.rowsCount
      ),
      size: size
    )
    Task {
      await store.reportPumBounds(rectangle: rectangle)
    }
  }
}

private class TableView: NSTableView {
  override var acceptsFirstResponder: Bool {
    false
  }
}
