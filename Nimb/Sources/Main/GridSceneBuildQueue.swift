// SPDX-License-Identifier: MIT

// Explicitly nonisolated: the app target defaults to MainActor, and the whole
// point of this type is to run off it.

import AppKit
import NimbCore
import NimbState
import Synchronization

/// Turns grid snapshots into Metal frames away from the main actor.
///
/// Scene building used to run inline in GridView.render on the main actor. For
/// a full-screen grid that is roughly ten thousand atlas lookups and instance
/// appends, plus any glyph rasterisation the frame happens to miss on, all of
/// it between AppKit and the next event it could have handled — which is what
/// a fast scroll feels as stutter.
///
/// One drain task services every grid rather than one per grid. Serialising
/// costs nothing here (the goal is to unblock main, not to saturate cores) and
/// buys two things: delivery to a given layer stays in frame order, and the
/// glyph atlas — shared by every grid and not internally synchronised — is only
/// ever touched from one thread.
final nonisolated class GridSceneBuildQueue: Sendable {
  /// Unchecked because it carries a CALayer and a builder, neither of which is
  /// Sendable. Both are only reached from the drain task, one request at a
  /// time, and `bounds`/`scale` are captured on the main actor at submit time
  /// precisely so the drain task never has to read them off the layer.
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

  /// Explicitly off the main actor. A bare `Task {}` started from `submit`
  /// would inherit its MainActor isolation and put the whole build back where
  /// it came from.
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

      // One hop for the whole batch rather than one per grid. The requests in
      // a batch come from the same frame, so marking them dirty together is
      // also what keeps the grids of one frame from reaching the screen in
      // two different compositor transactions.
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
        // Cleared under the same lock that submit checks, so a request
        // arriving now is guaranteed to start a new drain rather than be left
        // sitting for one that is already returning.
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
