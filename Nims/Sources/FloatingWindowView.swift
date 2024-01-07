// SPDX-License-Identifier: MIT

import AppKit

public class FloatingWindowView: NSView {
  public init(store: Store, observedHighlightName: Appearance.ObservedHighlightName = .normalFloat) {
    self.store = store
    self.observedHighlightName = observedHighlightName
    super.init(frame: .zero)
    wantsLayer = true
    shadow = .init()
    layer!.cornerRadius = 8
    layer!.borderWidth = 1
    layer!.shadowRadius = 5
    layer!.shadowOffset = .init(width: 4, height: -4)
    layer!.shadowOpacity = 0.3
    layer!.shadowColor = .black
    renderAppearance()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @discardableResult
  public func animate(hide: Bool, completionHandler: @escaping (_ isCompleted: Bool) -> Void = { _ in }) -> Bool {
    if hide {
      if isVisibleAnimatedOn != false {
        isVisibleAnimatedOn = false
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.1
          animator().alphaValue = 0
        } completionHandler: { [weak self] in
          guard let self else {
            return
          }
          if isVisibleAnimatedOn == false {
            isHidden = true
          }
          completionHandler(isVisibleAnimatedOn == false)
        }
        return true
      } else {
        return false
      }
    } else {
      if isVisibleAnimatedOn != true {
        isVisibleAnimatedOn = true
        isHidden = false
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.1
          animator().alphaValue = 1
        } completionHandler: { [weak self] in
          guard let self else {
            return
          }
          completionHandler(isVisibleAnimatedOn == true)
        }
        return true
      } else {
        return false
      }
    }
  }

  public func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isAppearanceUpdated, stateUpdates.updatedObservedHighlightNames.contains(observedHighlightName) {
      renderAppearance()
    }
  }

  private let store: Store
  private let observedHighlightName: Appearance.ObservedHighlightName
  private var isVisibleAnimatedOn: Bool?

  private func renderAppearance() {
    layer!.backgroundColor = store.state.appearance.backgroundColor(for: observedHighlightName)
      .appKit
      .cgColor
    layer!.borderColor = store.state.appearance.foregroundColor(for: observedHighlightName)
      .with(alpha: 0.3)
      .appKit
      .cgColor
  }
}
