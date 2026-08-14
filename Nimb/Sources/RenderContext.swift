// SPDX-License-Identifier: MIT

import Foundation
import NimbState
import ObjectiveC

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
@MainActor
public protocol Rendering {
  var renderContext: RenderContext { get }
  func update(renderContext: RenderContext)
  func render()
}

public extension Rendering {
  var state: State {
    renderContext.state
  }

  var updates: State.Updates {
    renderContext.updates
  }
}

public extension Rendering where Self: AnyObject {
  var isRendered: Bool {
    objc_getAssociatedObject(self, renderingContextAssociatedObjectKey) != nil
  }

  var renderContext: RenderContext {
    objc_getAssociatedObject(self, renderingContextAssociatedObjectKey) as! RenderContext
  }

  func update(renderContext: RenderContext) {
    objc_setAssociatedObject(
      self,
      renderingContextAssociatedObjectKey,
      renderContext,
      .OBJC_ASSOCIATION_RETAIN,
    )
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

/// Process-lifetime token used only for ObjC associated-object lookup.
private nonisolated(unsafe) let renderingContextAssociatedObjectKey: UnsafeRawPointer = .init(malloc(1)!)
