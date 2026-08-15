// SPDX-License-Identifier: MIT

import OSLog
import Synchronization

/// Signposts for the redraw-to-present pipeline, so Instruments can show where
/// a frame goes without guessing from a sampled profile.
///
/// Emitting a signpost is close to free when nothing is recording, so these
/// stay compiled in unconditionally. The aggregate counters behind
/// `renderStats` are the part that costs a clock read per call, and those are
/// gated on the debug flag.
/// Spelled out so the frame stats can be filtered for from outside the
/// process. The global `logger` is a bare `Logger()`, which carries no
/// subsystem at all, so `log stream --predicate 'subsystem == ...'` matches
/// nothing it writes.
public let renderSubsystem = "foxacid7cd.Nimb.rendering"

public let renderSignposter = OSSignposter(
  subsystem: renderSubsystem,
  category: "Rendering",
)

public let renderStatsLogger = Logger(
  subsystem: renderSubsystem,
  category: "FrameStats",
)

public enum RenderStage: Int, CaseIterable, Sendable {
  /// Applying actions to State on the reducer task.
  case reduce
  /// The whole main-actor render tree walk, once per coalesced frame.
  case frameHop
  /// Turning one grid's snapshot into Metal instance data.
  case sceneBuild
  /// Rasterizing a glyph into the atlas. Counted per cache miss, not per
  /// lookup, so a high count here means the atlas is thrashing.
  case glyphRasterize
  /// Acquiring a drawable, encoding and presenting one grid.
  case display

  public var name: String {
    switch self {
    case .reduce: "reduce"
    case .frameHop: "frame-hop"
    case .sceneBuild: "scene-build"
    case .glyphRasterize: "glyph-raster"
    case .display: "display"
    }
  }
}

/// Rolling per-stage timings, summarised to the log every `framesPerSummary`
/// frames. Instruments gives a better picture, but this makes a regression
/// visible from a plain run with no tooling attached.
public final class RenderStats: Sendable {
  private struct Bucket {
    var callCount = 0
    var totalNanoseconds: Int64 = 0
    var maxNanoseconds: Int64 = 0
  }

  private struct Storage {
    var isEnabled = false
    var frameCount = 0
    var buckets = [Bucket](repeating: .init(), count: RenderStage.allCases.count)
  }

  /// About a second of sustained redraw at 60Hz. Short enough that a scroll
  /// burst produces several summaries rather than one average over the whole
  /// gesture.
  private static let framesPerSummary = 60

  private let storage = Mutex(Storage())

  public var isEnabled: Bool {
    get { storage.withLock { $0.isEnabled } }
    set {
      storage.withLock { state in
        guard state.isEnabled != newValue else {
          return
        }
        // Start from a clean window rather than carrying counts across the
        // toggle, so a summary never mixes instrumented and uninstrumented
        // runs.
        state = .init(isEnabled: newValue)
      }
    }
  }

  public init() { }

  public func record(_ stage: RenderStage, _ duration: Duration) {
    let components = duration.components
    let nanoseconds = components.seconds * 1_000_000_000
      + components.attoseconds / 1_000_000_000

    storage.withLock { state in
      guard state.isEnabled else {
        return
      }
      state.buckets[stage.rawValue].callCount += 1
      state.buckets[stage.rawValue].totalNanoseconds += nanoseconds
      state.buckets[stage.rawValue].maxNanoseconds = max(
        state.buckets[stage.rawValue].maxNanoseconds,
        nanoseconds,
      )
    }
  }

  /// Called once per presented frame. Emits a summary and starts a new window
  /// every `framesPerSummary` frames.
  public func frameCompleted() {
    let summary: String? = storage.withLock { state in
      guard state.isEnabled else {
        return nil
      }
      state.frameCount += 1
      guard state.frameCount >= Self.framesPerSummary else {
        return nil
      }

      let frameCount = state.frameCount
      let description = RenderStage.allCases
        .map { stage -> String in
          let bucket = state.buckets[stage.rawValue]
          guard bucket.callCount > 0 else {
            return "\(stage.name) -"
          }
          let mean = Double(bucket.totalNanoseconds) / Double(bucket.callCount) / 1_000_000
          let peak = Double(bucket.maxNanoseconds) / 1_000_000
          let perFrame = Double(bucket.callCount) / Double(frameCount)
          return String(
            format: "%@ %.2f/%.2fms x%.1f",
            stage.name,
            mean,
            peak,
            perFrame,
          )
        }
        .joined(separator: "  ")

      state.frameCount = 0
      state.buckets = .init(
        repeating: .init(),
        count: RenderStage.allCases.count,
      )
      return "frame stats over \(frameCount) frames (mean/peak per call, calls per frame): \(description)"
    }

    if let summary {
      // Notice rather than info: info-level entries are memory-only unless
      // something is actively streaming, so a summary written before the
      // stream attached would be lost.
      // Explicitly public: os_log redacts interpolated strings by default, so
      // without this every summary reads as <private> from `log show`.
      renderStatsLogger.notice("\(summary, privacy: .public)")
    }
  }
}

public let renderStats = RenderStats()

/// Wraps `body` in a signpost interval and, when frame stats are enabled, in a
/// clock read. The clock read is skipped entirely when they are not, so this is
/// safe to leave on hot paths.
@inline(__always)
public func measuringRenderStage<T>(
  _ name: StaticString,
  _ stage: RenderStage,
  _ body: () throws -> T,
)
rethrows -> T {
  guard renderStats.isEnabled else {
    return try renderSignposter.withIntervalSignpost(name, around: body)
  }

  let start = ContinuousClock.now
  defer { renderStats.record(stage, ContinuousClock.now - start) }
  return try renderSignposter.withIntervalSignpost(name, around: body)
}
