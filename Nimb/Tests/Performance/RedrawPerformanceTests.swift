// SPDX-License-Identifier: MIT

import NimbCore
import NimbNeovim
import NimbState
import XCTest

@MainActor
final class RedrawPerformanceTests: XCTestCase {
  private let columnsCount = 160
  private let rowsCount = 60

  func testDecodeRedrawFramePerformance() {
    let data = Packer().pack(redrawMessageValue())
    let options = XCTMeasureOptions()
    options.iterationCount = 10

    measure(metrics: [XCTClockMetric(), XCTMemoryMetric()], options: options) {
      do {
        let values = try Unpacker().unpack(data)
        let messages = try values.map(Message.init(value:))
        guard case let .notification(notification) = messages.first else {
          XCTFail("Expected a redraw notification")
          return
        }
        let events = try [UIEvent](rawRedrawNotificationParameters: notification.parameters)
        XCTAssertEqual(events.count, 3)
      } catch {
        XCTFail("Failed to decode redraw frame: \(error)")
      }
    }
  }

  func testReduceRedrawFramePerformance() throws {
    let events = try decodedEvents()
    let font = Font()
    let options = XCTMeasureOptions()
    options.iterationCount = 10

    measure(metrics: [XCTClockMetric(), XCTMemoryMetric()], options: options) {
      var state = State(font: font)
      _ = Actions.ApplyUIEvents(uiEvents: events).apply(to: &state) { error in
        XCTFail("Failed to apply redraw frame: \(error)")
      }
      XCTAssertEqual(state.outerGrid?.size.columnsCount, self.columnsCount)
      XCTAssertEqual(state.outerGrid?.size.rowsCount, self.rowsCount)
    }
  }

  private func decodedEvents() throws -> [UIEvent] {
    let value = try XCTUnwrap(Unpacker().unpack(Packer().pack(redrawMessageValue())).first)
    let message = try Message(value: value)
    guard case let .notification(notification) = message else {
      throw PerformanceFixtureError.expectedNotification
    }
    return try [UIEvent](rawRedrawNotificationParameters: notification.parameters)
  }

  private func redrawMessageValue() -> Value {
    let resize: Value = .array([
      "grid_resize",
      .array([.integer(1), .integer(columnsCount), .integer(rowsCount)]),
    ])
    let lines: Value = .array(
      ["grid_line"] + (0 ..< rowsCount).map { row in
        .array([
          .integer(1),
          .integer(row),
          .integer(0),
          .cellRuns([
            .init(text: "l", highlightID: 1, repeatCount: 20),
            .init(text: " ", highlightID: 0, repeatCount: 4),
            .init(text: "v", highlightID: 2, repeatCount: 30),
            .init(text: " ", highlightID: 0, repeatCount: 4),
            .init(text: "=", highlightID: 3),
            .init(text: " ", highlightID: 0, repeatCount: 4),
            .init(text: "0", highlightID: 4),
            .init(text: " ", highlightID: 0, repeatCount: columnsCount - 64),
          ]),
          false,
        ])
      },
    )
    return .array([
      .integer(2),
      "redraw",
      .array([resize, lines, .array(["flush", .array([])])]),
    ])
  }
}

private enum PerformanceFixtureError: Error {
  case expectedNotification
}
