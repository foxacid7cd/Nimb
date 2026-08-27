// SPDX-License-Identifier: MIT

import NimbState

public final class RenderContext: Sendable {
  public let state: State
  public let updates: State.Updates

  public init(state: State, updates: State.Updates) {
    self.state = state
    self.updates = updates
  }
}

/// Isolated to the main actor, so the render tree is walked synchronously from
/// the top rather than fanning one frame out into unordered tasks.
@MainActor
public protocol Rendering: AnyObject {
  var renderContext: RenderContext! { get set }
  func render()
}

public extension Rendering {
  var state: State {
    renderContext.state
  }

  var updates: State.Updates {
    renderContext.updates
  }

  var isRendered: Bool {
    renderContext != nil
  }

  func update(renderContext: RenderContext) {
    self.renderContext = renderContext
  }

  func renderChildren(_ children: any Sequence<Rendering>) {
    for child in children {
      child.update(renderContext: renderContext)
      child.render()
    }
  }

  func renderChildren(_ children: (any Rendering)...) {
    renderChildren(children)
  }
}
