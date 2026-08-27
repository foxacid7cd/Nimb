// SPDX-License-Identifier: MIT

import OSLog
import Synchronization

/// Named so frame stats can be filtered for from outside the process; the
/// global `logger` carries no subsystem at all.
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

/// Things worth counting per frame rather than timing.
public enum RenderCounter: Int, CaseIterable, Sendable {
  /// Grids the render walk visited.
  case gridsVisited
  /// Grids that visit decided actually needed a new scene. The ratio against
  /// visited is what says whether skipping clean grids is working.
  case gridsBuilt
  /// Frames carrying isAppearanceUpdated, which forces every grid to rebuild.
  /// Approaching one per frame means no per-grid skipping can fire.
  case appearanceUpdatedFrames

  public var name: String {
    switch self {
    case .gridsVisited: "visited"
    case .gridsBuilt: "built"
    case .appearanceUpdatedFrames: "appearance"
    }
  }
}

/// Rolling per-stage timings, summarised to the log every `framesPerSummary`
/// frames, so a regression is visible from a plain run with no tooling.
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
    var counters = [Int](repeating: 0, count: RenderCounter.allCases.count)
  }

  /// About a second of sustained redraw at 60Hz, so a scroll burst produces
  /// several summaries rather than one average.
  private static let framesPerSummary = 60

  private let storage = Mutex(Storage())

  public var isEnabled: Bool {
    get { storage.withLock { $0.isEnabled } }
    set {
      storage.withLock { state in
        guard state.isEnabled != newValue else {
          return
        }
        // Start from a clean window, so a summary never mixes instrumented and
        // uninstrumented runs.
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

  public func count(_ counter: RenderCounter) {
    storage.withLock { state in
      guard state.isEnabled else {
        return
      }
      state.counters[counter.rawValue] += 1
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

      let counters = RenderCounter.allCases
        .map { counter -> String in
          String(
            format: "%@ %.1f",
            counter.name,
            Double(state.counters[counter.rawValue]) / Double(frameCount),
          )
        }
        .joined(separator: "/")

      state.frameCount = 0
      state.buckets = .init(
        repeating: .init(),
        count: RenderStage.allCases.count,
      )
      state.counters = .init(repeating: 0, count: RenderCounter.allCases.count)
      return "frame stats over \(frameCount) frames (mean/peak per call, calls per frame): \(description)  |  grids/frame \(counters)"
    }

    if let summary {
      // Notice rather than info, which is memory-only until something streams.
      // Explicitly public, since os_log redacts interpolated strings.
      renderStatsLogger.notice("\(summary, privacy: .public)")
    }
  }
}

public let renderStats = RenderStats()

/// Wraps `body` in a signpost interval, and in a clock read only when frame
/// stats are enabled, so this is safe to leave on hot paths.
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
