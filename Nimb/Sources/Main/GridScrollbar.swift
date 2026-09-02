// SPDX-License-Identifier: MIT

import AppKit
import NimbNeovim

struct GridScrollbarGeometry: Equatable {
  static let hitWidth: CGFloat = 12
  static let thumbWidth: CGFloat = 4
  static let thumbInset: CGFloat = 3
  static let minimumThumbHeight: CGFloat = 20

  var track: CGRect
  var thumbHeight: CGFloat
  var scrollableLineCount: Int
  var topLine: Int

  var hitFrame: CGRect {
    .init(
      x: track.maxX - Self.hitWidth,
      y: track.minY,
      width: Self.hitWidth,
      height: track.height,
    )
  }

  init?(
    bounds: CGRect,
    gridRows: Int,
    cellHeight: CGFloat,
    topMarginRows: Int,
    bottomMarginRows: Int,
    lineCount: Int,
    topLine: Int,
  ) {
    guard lineCount > 0 else {
      return nil
    }

    let topInset = CGFloat(topMarginRows) * cellHeight
    let bottomInset = CGFloat(bottomMarginRows) * cellHeight
    let track = CGRect(
      x: bounds.minX,
      y: bounds.minY + bottomInset,
      width: bounds.width,
      height: bounds.height - topInset - bottomInset,
    )
    let visibleLineCount = max(gridRows - topMarginRows - bottomMarginRows, 1)
    let thumbHeight = max(
      Self.minimumThumbHeight,
      track.height * CGFloat(visibleLineCount) / CGFloat(lineCount),
    )
    let scrollableLineCount = lineCount - visibleLineCount
    guard track.height > 0, thumbHeight < track.height, scrollableLineCount > 0 else {
      return nil
    }

    self.track = track
    self.thumbHeight = thumbHeight
    self.scrollableLineCount = scrollableLineCount
    self.topLine = topLine
  }

  func progress(for requestedTopLine: Int? = nil) -> CGFloat {
    min(
      max(CGFloat(requestedTopLine ?? topLine) / CGFloat(scrollableLineCount), 0),
      1,
    )
  }

  func thumbFrame(progress: CGFloat) -> CGRect {
    let thumbTravel = track.height - thumbHeight
    return .init(
      x: track.maxX - Self.thumbWidth - Self.thumbInset,
      y: track.maxY - thumbHeight - progress * thumbTravel,
      width: Self.thumbWidth,
      height: thumbHeight,
    )
  }

  func topLine(at y: CGFloat, dragOffset: CGFloat) -> (topLine: Int, progress: CGFloat) {
    let thumbTravel = track.height - thumbHeight
    let thumbMinY = min(
      max(y - dragOffset, track.minY),
      track.maxY - thumbHeight,
    )
    let progress = (track.maxY - thumbHeight - thumbMinY) / thumbTravel
    return (
      topLine: Int((progress * CGFloat(scrollableLineCount)).rounded()),
      progress: progress,
    )
  }
}

final class GridScrollbar {
  let layer = CALayer()

  private let scroll: (References.Window, Int) -> Void
  private var hideTask: Task<Void, Never>? = nil
  private var isHovered = false
  private var dragOffset: CGFloat? = nil
  private var requestedTopLine: Int? = nil

  init(scroll: @escaping (References.Window, Int) -> Void) {
    self.scroll = scroll
    layer.backgroundColor = NSColor.labelColor.withAlphaComponent(0.35).cgColor
    layer.cornerRadius = GridScrollbarGeometry.thumbWidth / 2
    layer.opacity = 0
  }

  func begin(
    at location: CGPoint,
    geometry: GridScrollbarGeometry,
    windowID: References.Window,
  )
  -> Bool {
    guard geometry.hitFrame.contains(location) else {
      return false
    }

    cancelHide()
    setVisible(true)

    let thumbFrame = geometry.thumbFrame(progress: geometry.progress(for: requestedTopLine))
    if thumbFrame.minY ... thumbFrame.maxY ~= location.y {
      dragOffset = location.y - thumbFrame.minY
    } else {
      dragOffset = geometry.thumbHeight / 2
      update(at: location, geometry: geometry, windowID: windowID)
    }
    return true
  }

  func updateHover(at location: CGPoint, geometry: GridScrollbarGeometry) -> Bool {
    guard geometry.hitFrame.contains(location) else {
      endHover()
      return false
    }

    isHovered = true
    cancelHide()
    setVisible(true)
    return true
  }

  func endHover() {
    guard isHovered else {
      return
    }
    isHovered = false
    if dragOffset == nil {
      scheduleHide()
    }
  }

  func update(
    at location: CGPoint,
    geometry: GridScrollbarGeometry,
    windowID: References.Window,
  ) {
    guard let dragOffset else {
      return
    }
    let position = geometry.topLine(at: location.y, dragOffset: dragOffset)
    guard position.topLine != requestedTopLine else {
      return
    }

    requestedTopLine = position.topLine
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    layer.frame = geometry.thumbFrame(progress: position.progress)
    CATransaction.commit()
    scroll(windowID, position.topLine)
  }

  func endInteraction() {
    guard dragOffset != nil else {
      return
    }
    dragOffset = nil
    requestedTopLine = nil
    if !isHovered {
      scheduleHide()
    }
  }

  func render(geometry: GridScrollbarGeometry?, viewportUpdated: Bool) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    defer { CATransaction.commit() }

    if viewportUpdated {
      requestedTopLine = nil
      if dragOffset != nil, NSEvent.pressedMouseButtons & 1 == 0 {
        dragOffset = nil
      }
    }

    guard let geometry else {
      cancelHide()
      setVisible(false)
      return
    }

    layer.frame = geometry.thumbFrame(progress: geometry.progress(for: requestedTopLine))
    if dragOffset != nil {
      setVisible(true)
    } else if viewportUpdated {
      setVisible(true)
      if !isHovered {
        scheduleHide()
      }
    }
  }

  private func scheduleHide() {
    hideTask?.cancel()
    hideTask = Task { @MainActor [weak self] in
      try? await Task.sleep(for: .seconds(1.5))
      guard !Task.isCancelled, let self, !isHovered, dragOffset == nil else {
        return
      }
      setVisible(false)
    }
  }

  private func cancelHide() {
    hideTask?.cancel()
    hideTask = nil
  }

  private func setVisible(_ isVisible: Bool) {
    let opacity: Float = isVisible ? 1 : 0
    guard layer.opacity != opacity else {
      return
    }

    let currentOpacity = layer.presentation()?.opacity ?? layer.opacity
    layer.opacity = opacity

    let animation = CABasicAnimation(keyPath: "opacity")
    animation.fromValue = currentOpacity
    animation.toValue = opacity
    animation.duration = 0.16
    animation.timingFunction = .init(name: .easeInEaseOut)
    layer.add(animation, forKey: "visibility")
  }
}
