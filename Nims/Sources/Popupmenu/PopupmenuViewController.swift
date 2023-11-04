// SPDX-License-Identifier: MIT

import AppKit

public final class PopupmenuViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
  public init(store: Store) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func reloadData() {
    tableView.reloadData()
  }

  public func scrollTo(itemAtIndex index: Int) {
    tableView.scrollRowToVisible(index)
  }

  override public func loadView() {
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

  override public func viewWillAppear() {
    super.viewWillAppear()

    scrollView.contentView.scroll(to: .init(
      x: -scrollView.contentInsets.left,
      y: -scrollView.contentInsets.top
    ))
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
      itemView!.set(item: popupmenu.items[row], isSelected: popupmenu.selectedItemIndex == row, font: store.font)
    }
    return itemView
  }

  public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    store.reportPopupmenuItemSelected(atIndex: row)
    return false
  }

  private let store: Store
  private let scrollView = NSScrollView()
  private let tableView = NSTableView()
}
