// SPDX-License-Identifier: MIT

import Foundation
import ObjectiveC

public final class RenderContext: Sendable {
  public let state: State
  public let updates: State.Updates

  public init(state: State, updates: State.Updates) {
    self.state = state
    self.updates = updates
  }
}

public protocol Rendering {
  @MainActor var renderContext: RenderContext { get }
  @MainActor func update(renderContext: RenderContext)
  @MainActor func render()
}

public extension Rendering {
  @MainActor var state: State {
    renderContext.state
  }

  @MainActor var updates: State.Updates {
    renderContext.updates
  }
}

public extension Rendering where Self: AnyObject {
  @MainActor var isRendered: Bool {
    withUnsafePointer(
      to: &renderingContextAssociatedObjectKey
    ) { keyPointer in
      objc_getAssociatedObject(self, keyPointer) != nil
    }
  }

  @MainActor var renderContext: RenderContext {
    withUnsafePointer(
      to: &renderingContextAssociatedObjectKey
    ) { keyPointer in
      objc_getAssociatedObject(self, keyPointer) as! RenderContext
    }
  }

  @MainActor func update(renderContext: RenderContext) {
    withUnsafePointer(
      to: &renderingContextAssociatedObjectKey
    ) { keyPointer in
      objc_setAssociatedObject(
        self,
        keyPointer,
        renderContext,
        .OBJC_ASSOCIATION_RETAIN
      )
    }
  }

  @MainActor func renderChildren(_ children: any Sequence<Rendering>) {
    for child in children {
      child.update(renderContext: renderContext)
      child.render()
    }
  }

  @MainActor func renderChildren(_ children: (any Rendering)...) {
    renderChildren(children)
  }
}

@MainActor private var renderingContextAssociatedObjectKey: String = "renderingContextAssociatedObjectKey"
