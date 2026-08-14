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

/// Isolated to the main actor: every conformer is an AppKit object, and the
/// render tree is walked synchronously from the top. Before this was isolated,
/// each conformer satisfied a nonisolated requirement by hopping to the main
/// actor itself, so a single frame fanned out into a set of unstructured tasks
/// whose relative order was unspecified — frame N+1 could interleave with
/// frame N.
///
/// Conformers store the context themselves. It used to be smuggled through an
/// ObjC associated object so the protocol could provide it without a stored
/// property, which cost a force-cast on every read and a deliberately leaked
/// key.
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
