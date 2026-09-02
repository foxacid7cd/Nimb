// SPDX-License-Identifier: MIT

import AppKit
import Collections
import NimbCore
import NimbState

private final class MessageSeparatorView: NSView {
  override var isFlipped: Bool {
    true
  }

  var character = " " {
    didSet { needsDisplay = true }
  }

  var font = Font() {
    didSet { needsDisplay = true }
  }

  var nvimAppearance = Appearance() {
    didSet { needsDisplay = true }
  }

  override func draw(_ dirtyRect: NSRect) {
    let name = Appearance.ObservedHighlightName.msgSeparator
    nvimAppearance.backgroundColor(for: name).appKit.setFill()
    dirtyRect.fill()

    guard !character.isEmpty, font.cellWidth > 0 else {
      return
    }

    let attributes: [NSAttributedString.Key: Any] = [
      .font: font.appKit(
        isBold: nvimAppearance.isBold(for: name),
        isItalic: nvimAppearance.isItalic(for: name),
      ),
      .foregroundColor: nvimAppearance.foregroundColor(for: name).appKit,
    ]
    let string = character as NSString
    let textSize = string.size(withAttributes: attributes)
    let columnsCount = Int(ceil(bounds.width / font.cellWidth))
    let y = (bounds.height - textSize.height) / 2
    for column in 0 ..< columnsCount {
      let cellX = Double(column) * font.cellWidth
      let x = cellX + (font.cellWidth - textSize.width) / 2
      string.draw(at: .init(x: x, y: y), withAttributes: attributes)
    }
  }
}

public class GridsView: NSView, Rendering {
  private enum LeftMouseInteraction {
    case editor(GridView)
    case scrollbar(GridView)
  }

  override public var intrinsicContentSize: NSSize {
    guard isRendered, let outerGrid = state.outerGrid else {
      return .zero
    }
    return outerGrid.size * state.font.cellSize
  }

  public var renderContext: RenderContext! = nil

  private var store: Store
  private var arrangedGridViews = IntKeyedDictionary<GridView>()
  private let messageSeparatorView = MessageSeparatorView()
  private var leftMouseInteraction: LeftMouseInteraction? = nil
  private var scrollbarHoverTarget: GridView? = nil
  private var rightMouseInteractionTarget: GridView? = nil
  private var otherMouseInteractionTarget: GridView? = nil

  public var upsideDownTransform: CGAffineTransform {
    .init(scaleX: 1, y: -1)
      .translatedBy(
        x: 0,
        y: -Double(state.outerGrid!.rowsCount) * state.font.cellHeight,
      )
  }

  init(store: Store) {
    self.store = store
    super.init(frame: .init())

    canDrawConcurrently = true
    messageSeparatorView.isHidden = true
    addSubview(messageSeparatorView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Mouse events are handled here rather than by the grid views themselves.
  /// Reordering subviews drops AppKit's mouse-down view, so a drag started on
  /// a separator would be re-hit-tested onto whichever grid slid under the
  /// cursor and report coordinates in that grid's space instead.
  override public func hitTest(_ point: NSPoint) -> NSView? {
    let localPoint = superview.map { convert(point, from: $0) } ?? point
    return bounds.contains(localPoint) ? self : nil
  }

  override public func updateTrackingAreas() {
    super.updateTrackingAreas()

    for trackingArea in trackingAreas {
      removeTrackingArea(trackingArea)
    }
    addTrackingArea(.init(
      rect: bounds,
      options: [.inVisibleRect, .activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited],
      owner: self,
      userInfo: nil,
    ))
  }

  override public func mouseMoved(with event: NSEvent) {
    let target = gridView(for: event)
    let newHoverTarget = target?.updateScrollbarHover(with: event) == true ? target : nil
    if scrollbarHoverTarget !== newHoverTarget {
      scrollbarHoverTarget?.endScrollbarHover()
      scrollbarHoverTarget = newHoverTarget
    }
  }

  override public func mouseExited(with _: NSEvent) {
    scrollbarHoverTarget?.endScrollbarHover()
    scrollbarHoverTarget = nil
  }

  override public func mouseDown(with event: NSEvent) {
    if case let .scrollbar(target) = leftMouseInteraction {
      target.endScrollbarInteraction()
    }
    guard let target = gridView(for: event) else {
      leftMouseInteraction = nil
      return
    }
    if target.beginScrollbarInteraction(with: event) {
      leftMouseInteraction = .scrollbar(target)
    } else {
      leftMouseInteraction = .editor(target)
      target.report(mouseButton: "left", action: "press", with: event)
    }
  }

  override public func mouseDragged(with event: NSEvent) {
    switch leftMouseInteraction {
    case let .editor(target):
      target.report(mouseButton: "left", action: "drag", with: event)
    case let .scrollbar(target):
      target.updateScrollbarInteraction(with: event)
    case nil:
      break
    }
  }

  override public func mouseUp(with event: NSEvent) {
    switch leftMouseInteraction {
    case let .editor(target):
      target.report(mouseButton: "left", action: "release", with: event)

    case let .scrollbar(target):
      target.updateScrollbarInteraction(with: event)
      target.endScrollbarInteraction()

    case nil:
      break
    }
    leftMouseInteraction = nil
  }

  override public func rightMouseDown(with event: NSEvent) {
    rightMouseInteractionTarget = gridView(for: event)
    rightMouseInteractionTarget?
      .report(mouseButton: "right", action: "press", with: event)
  }

  override public func rightMouseDragged(with event: NSEvent) {
    rightMouseInteractionTarget?
      .report(mouseButton: "right", action: "drag", with: event)
  }

  override public func rightMouseUp(with event: NSEvent) {
    rightMouseInteractionTarget?
      .report(mouseButton: "right", action: "release", with: event)
    rightMouseInteractionTarget = nil
  }

  override public func otherMouseDown(with event: NSEvent) {
    otherMouseInteractionTarget = gridView(for: event)
    otherMouseInteractionTarget?
      .report(mouseButton: "middle", action: "press", with: event)
  }

  override public func otherMouseDragged(with event: NSEvent) {
    otherMouseInteractionTarget?
      .report(mouseButton: "middle", action: "drag", with: event)
  }

  override public func otherMouseUp(with event: NSEvent) {
    otherMouseInteractionTarget?
      .report(mouseButton: "middle", action: "release", with: event)
    otherMouseInteractionTarget = nil
  }

  override public func scrollWheel(with event: NSEvent) {
    gridView(for: event)?.scrollWheel(with: event)
  }

  public func render() {
    for gridID in updates.destroyedGridIDs {
      let view = arrangedGridView(forGridWithID: gridID)
      view.setHiddenByState(true)
    }

    let updatedLayoutGridIDs =
      if updates.isFontUpdated {
        Set(state.grids.keys)

      } else {
        updates.updatedLayoutGridIDs
      }

    for gridID in updatedLayoutGridIDs {
      guard let grid = state.grids[gridID] else {
        continue
      }

      let gridView = arrangedGridView(forGridWithID: gridID)
      gridView.setHiddenByState(grid.isHidden)

      if gridID == Grid.OuterID {
        invalidateIntrinsicContentSize()
      } else if let associatedWindow = grid.associatedWindow {
        switch associatedWindow {
        case .external:
          gridView.setHiddenByState(true)

        default:
          break
        }
      }
    }

    if
      !updatedLayoutGridIDs.isEmpty
      || updates.isGridsHierarchyUpdated
      || updates.isAppearanceUpdated
      || updates.updatedObservedHighlightNames.contains(.msgSeparator)
    {
      let upsideDownTransform = upsideDownTransform

      // walkingGridFrames yields back to front, so this is the stacking order.
      var orderedGridViews = [NSView]()
      messageSeparatorView.isHidden = true

      state.walkingGridFrames { id, frame, _ in
        guard let gridView = arrangedGridViews[id] else {
          logger.warning("walkingGridFrames: gridView with id \(id) not found")
          return
        }

        let newFrame = snappedToDevicePixels(frame.applying(upsideDownTransform))
        if gridView.frame != newFrame {
          gridView.frame = newFrame
        }

        if
          case let .floating(window) = state.grids[id]?.associatedWindow,
          let separator = window.messageSeparator
        {
          messageSeparatorView.character = separator
          messageSeparatorView.font = state.font
          messageSeparatorView.nvimAppearance = state.appearance
          messageSeparatorView.frame = snappedToDevicePixels(.init(
            x: newFrame.minX,
            y: newFrame.maxY,
            width: newFrame.width,
            height: state.font.cellHeight,
          ))
          messageSeparatorView.isHidden = false
          orderedGridViews.append(messageSeparatorView)
        }
        orderedGridViews.append(gridView)
      }

      // Apply it. subviews[0] is the backmost view in AppKit, which matches
      // the order above. Anything walkingGridFrames did not visit — hidden or
      // external grids — keeps its relative position underneath.
      let ordered = Set(orderedGridViews.map(ObjectIdentifier.init))
      let unvisited = subviews.filter { !ordered.contains(ObjectIdentifier($0)) }
      let newSubviews = unvisited + orderedGridViews
      if subviews != newSubviews {
        subviews = newSubviews
      }
    }

    renderChildren(arrangedGridViews.values.lazy.map(\.self))
  }

  public func windowFrame(
    forGridID gridID: Grid.ID,
    gridFrame: IntegerRectangle,
  )
    -> CGRect?
  {
    arrangedGridViews[gridID]?.windowFrame(forGridFrame: gridFrame)
  }

  public func arrangedGridView(forGridWithID id: Grid.ID) -> GridView {
    if let view = arrangedGridViews[id] {
      return view

    } else {
      let view = GridView(
        frame: .init(x: 0, y: 0, width: 200, height: 200),
        store: store,
        gridID: id,
      )
      renderChildren(view)
      view.autoresizingMask = []
      view.translatesAutoresizingMaskIntoConstraints = false
      addSubview(view)
      arrangedGridViews[id] = view
      return view
    }
  }

  /// A grid view's frame is a multiple of the cell size, which is fractional,
  /// so its layer would land between device pixels and be resampled onto them.
  /// The top-left corner is what the glyphs are laid out from, so that is the
  /// corner rounded to the nearest pixel; the rest grows outwards.
  private func snappedToDevicePixels(_ frame: CGRect) -> CGRect {
    let scale = window?.backingScaleFactor ?? 1
    guard scale > 0 else {
      return frame
    }
    let minX = (frame.minX * scale).rounded() / scale
    let maxY = (frame.maxY * scale).rounded() / scale
    let maxX = (frame.maxX * scale).rounded(.up) / scale
    let minY = (frame.minY * scale).rounded(.down) / scale
    return .init(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
  }

  /// Frontmost visible grid under the event, or the outer grid: separators and
  /// status lines are drawn by Neovim on the outer grid, in the gaps window
  /// grids leave behind.
  private func gridView(for event: NSEvent) -> GridView? {
    let location = convert(event.locationInWindow, from: nil)
    for case let gridView as GridView in subviews.reversed()
      where !gridView.isHidden
      && state.grids[gridView.gridID]?.isFocusable == true
      && gridView.frame.contains(location)
    {
      return gridView
    }
    return arrangedGridViews[Grid.OuterID]
  }

  private func point(for event: NSEvent) -> IntegerPoint {
    let upsideDownLocation = convert(event.locationInWindow, from: nil)
      .applying(upsideDownTransform)
    return .init(
      column: Int((upsideDownLocation.x / state.font.cellWidth).rounded(.down)),
      row: Int((upsideDownLocation.y / state.font.cellHeight).rounded(.down)),
    )
  }
}
