// SPDX-License-Identifier: MIT

// Explicitly nonisolated: the app target defaults to MainActor, and the whole
// point of this type is to run off it.

import AppKit
import NimbCore
import NimbState
import Synchronization

/// Turns grid snapshots into Metal frames away from the main actor. One drain
/// task for all grids, so delivery stays ordered and the atlas sees one thread.
final nonisolated class GridSceneBuildQueue: Sendable {
  /// Unchecked because it carries a CALayer and a builder, both reached only
  /// from the drain task. `bounds`/`scale` are captured at submit time.
  private struct Request: @unchecked Sendable {
    let target: GridLayer
    let builder: GridMetalSceneBuilder
    let snapshot: GridDrawSnapshot
    let updates: State.Updates
    let bounds: CGRect
    let scale: CGFloat
  }

  private struct Storage {
    /// Latest request per grid. A grid that submits twice before the drain
    /// reaches it only gets built once, at its newest snapshot.
    var requests = [Grid.ID: Request]()
    /// Submission order, so grids are built in the order they were asked for
    /// rather than in dictionary order.
    var gridIDs = [Grid.ID]()
    var isDraining = false
  }

  static let shared = GridSceneBuildQueue()

  private let storage = Mutex(Storage())

  private init() { }

  @MainActor
  func submit(
    gridID: Grid.ID,
    target: GridLayer,
    builder: GridMetalSceneBuilder,
    snapshot: GridDrawSnapshot,
    updates: State.Updates,
    bounds: CGRect,
    scale: CGFloat,
  ) {
    let request = Request(
      target: target,
      builder: builder,
      snapshot: snapshot,
      updates: updates,
      bounds: bounds,
      scale: scale,
    )

    let shouldStartDraining = storage.withLock { state in
      if state.requests.updateValue(request, forKey: gridID) == nil {
        state.gridIDs.append(gridID)
      }
      guard !state.isDraining else {
        return false
      }
      state.isDraining = true
      return true
    }

    if shouldStartDraining {
      Task { await drain() }
    }
  }

  /// Explicitly off the main actor: a bare `Task {}` from `submit` would
  /// inherit its isolation and put the build back where it came from.
  @concurrent
  private func drain() async {
    while true {
      let batch = takePendingRequests()
      guard !batch.isEmpty else {
        return
      }

      for request in batch {
        let metalFrame = request.builder.makeFrame(
          snapshot: request.snapshot,
          updates: request.updates,
          bounds: request.bounds,
          scale: request.scale,
        )
        request.target.update(
          renderInput: .init(
            snapshot: request.snapshot,
            updates: request.updates,
            metalFrame: metalFrame,
          ),
        )
      }

      // One hop for the whole batch, so the grids of one frame reach the screen
      // in a single compositor transaction.
      await MainActor.run {
        for request in batch {
          request.target.render()
        }
      }
    }
  }

  private func takePendingRequests() -> [Request] {
    storage.withLock { state in
      guard !state.gridIDs.isEmpty else {
        // Cleared under the same lock submit checks, so a request arriving now
        // starts a new drain rather than waiting on one that is returning.
        state.isDraining = false
        return []
      }

      let batch = state.gridIDs.compactMap { state.requests[$0] }
      state.requests.removeAll(keepingCapacity: true)
      state.gridIDs.removeAll(keepingCapacity: true)
      return batch
    }
  }
}
