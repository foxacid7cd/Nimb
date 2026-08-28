// SPDX-License-Identifier: MIT

import AppKit
import NimbCore
import NimbState

public class PopupmenuViewController: NSViewController, Rendering {
  /// Size of the menu when it hangs off a grid, where nothing else decides it.
  /// The cmdline anchor takes its width from the cmdline instead.
  private static let gridAnchoredWidth: CGFloat = 290
  private static let menuHeight: CGFloat = 156

  public var renderContext: RenderContext! = nil

  public var anchorConstraints = [NSLayoutConstraint]()

  public var willShowPopupmenu: (() -> Void)? = nil

  private let store: Store
  private let getCmdlinesView: () -> NSView
  private let getGridsView: () -> NSView
  private lazy var customView = FloatingWindowView()
  private lazy var scrollView = NSScrollView()
  private lazy var tableView = TableView()
  private var previousSelectedItemIndex: Int? = nil

  public init(
    store: Store,
    getCmdlinesView: @escaping () -> NSView,
    getGridsView: @escaping () -> NSView,
  ) {
    self.store = store
    self.getCmdlinesView = getCmdlinesView
    self.getGridsView = getGridsView
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func loadView() {
    let view = customView
    view.height(Self.menuHeight)

    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = .init(top: 8, left: 0, bottom: 8, right: 0)
    scrollView.drawsBackground = false
    view.addSubview(scrollView)
    scrollView.edgesToSuperview()

    tableView.headerView = nil
    tableView.delegate = self
    tableView.backgroundColor = .clear
    tableView.addTableColumn(
      .init(identifier: PopupmenuItemView.reuseIdentifier),
    )
    tableView.rowHeight = 28
    tableView.style = .fullWidth
    tableView.selectionHighlightStyle = .none
    scrollView.documentView = tableView

    self.view = view
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    customView.toggle(on: false)
  }

  public func render() {
    if tableView.dataSource == nil {
      tableView.dataSource = self
    }

    if let popupmenu = state.popupmenu {
      if updates.isPopupmenuUpdated {
        NSLayoutConstraint.deactivate(anchorConstraints)

        switch popupmenu.anchor {
        case let .grid(id, origin):
          var gridFrame: CGRect? = nil
          state.walkingGridFrames { walkedID, frame, _ in
            if walkedID == id {
              gridFrame = frame
            }
          }
          if let gridFrame {
            anchorConstraints = gridAnchorConstraints(
              origin: origin,
              gridFrame: gridFrame,
            )
          }

        case .cmdline:
          let cmdlinesView = getCmdlinesView()
          anchorConstraints = [
            view.leading(to: cmdlinesView),
            view.trailing(to: cmdlinesView),
            view.topToBottom(of: cmdlinesView, offset: 8),
          ]
        }
      }
      if updates.isPopupmenuUpdated || updates.isAppearanceUpdated {
        tableView.reloadData()
        storePreviousSelectedItemIndex(for: popupmenu)
        scrollToSelectedRow(for: popupmenu)
      } else if updates.isPopupmenuSelectionUpdated {
        scrollToSelectedRow(for: popupmenu)
        if
          let previousSelectedItemIndex,
          previousSelectedItemIndex < popupmenu.items.count,
          let selectedItemIndex = popupmenu.selectedItemIndex,
          selectedItemIndex < popupmenu.items.count
        {
          tableView.reloadData(
            forRowIndexes: [previousSelectedItemIndex, selectedItemIndex],
            columnIndexes: [0],
          )
        } else {
          tableView.reloadData()
        }
        storePreviousSelectedItemIndex(for: popupmenu)
      }
    }

    if updates.isPopupmenuUpdated {
      let on = state.popupmenu != nil
      if on {
        willShowPopupmenu?()
      }
      let isSuccess = customView.toggle(on: on)
      if on, isSuccess {
        scrollView.contentView.scroll(to: .init(
          x: -scrollView.contentInsets.left,
          y: -scrollView.contentInsets.top,
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
}

private extension PopupmenuViewController {
  /// Places the menu below the anchor cell, or above it when there is no room
  /// below, kept within the grids either way.
  ///
  /// Measured from the grids view rather than from any grid view: grid views
  /// carry imperative frames, and the frames state reports are the same ones
  /// they are laid out from, so this needs no live geometry to be right.
  func gridAnchorConstraints(
    origin: IntegerPoint,
    gridFrame: CGRect,
  )
    -> [NSLayoutConstraint]
  {
    let gridsView = getGridsView()
    let cellSize = state.font.cellSize
    let width = Self.gridAnchoredWidth
    let height = Self.menuHeight

    let outerSize = state.outerGrid?.size ?? .init()
    let gridsWidth = Double(outerSize.columnsCount) * cellSize.width
    let gridsHeight = Double(outerSize.rowsCount) * cellSize.height

    let anchorTop = gridFrame.minY + Double(origin.row) * cellSize.height
    var top = anchorTop + cellSize.height
    if top + height > gridsHeight {
      let above = anchorTop - height
      top = above >= 0 ? above : max(0, gridsHeight - height)
    }

    let leading = min(
      gridFrame.minX + Double(origin.column) * cellSize.width,
      max(0, gridsWidth - width),
    )

    return [
      view.leading(to: gridsView, offset: leading),
      view.top(to: gridsView, offset: top),
      view.width(width),
    ]
  }
}

extension PopupmenuViewController: NSTableViewDataSource, NSTableViewDelegate {
  public func numberOfRows(in tableView: NSTableView) -> Int {
    guard isRendered else {
      return 0
    }
    return state.popupmenu?.items.count ?? 0
  }

  public func tableView(
    _ tableView: NSTableView,
    viewFor tableColumn: NSTableColumn?,
    row: Int,
  )
    -> NSView?
  {
    guard isRendered else {
      return nil
    }
    var itemView = tableView.makeView(
      withIdentifier: PopupmenuItemView.reuseIdentifier,
      owner: self,
    ) as? PopupmenuItemView
    if itemView == nil {
      itemView = .init(store: store)
      itemView!.identifier = PopupmenuItemView.reuseIdentifier
    }
    if let popupmenu = state.popupmenu, row < popupmenu.items.count {
      itemView!.item = popupmenu.items[row]
      itemView!.isSelected = popupmenu.selectedItemIndex == row
      // Handed down explicitly: AppKit makes these views, so they are not
      // reached by renderChildren, and render() reads state through it.
      itemView!.update(renderContext: renderContext)
      itemView!.render()
    }
    return itemView
  }

  public func tableView(
    _: NSTableView,
    shouldSelectRow row: Int,
  )
    -> Bool
  {
//    store.reportPopupmenuItemSelected(atIndex: row, isFinish: false)
    false
  }
}

private class TableView: NSTableView {
  override var acceptsFirstResponder: Bool {
    false
  }
}
