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

  func testBatchedLineUpdatesMatchSequentialUpdates() {
    let font = Font()
    let appearance = Appearance()
    let updates = [
      Grid.LineUpdate(
        originColumn: 2,
        cells: [.init(character: "a", isDoubleWidth: false, highlightID: 1)],
        row: 0,
      ),
      Grid.LineUpdate(
        originColumn: 8,
        cells: [.init(character: "b", isDoubleWidth: false, highlightID: 2)],
        row: 0,
      ),
      Grid.LineUpdate(
        originColumn: 4,
        cells: [.init(character: "c", isDoubleWidth: false, highlightID: 3)],
        row: 1,
      ),
    ]
    var sequential = Grid(
      id: Grid.OuterID,
      size: .init(columnsCount: 12, rowsCount: 2),
      font: font,
      appearance: appearance,
    )
    var batched = sequential

    for update in updates {
      _ = sequential.applyLineUpdate(
        originColumn: update.originColumn,
        cells: update.cells,
        row: update.row,
        font: font,
        appearance: appearance,
      )
    }
    let dirtyRectangles = batched.applyLineUpdates(
      updates,
      font: font,
      appearance: appearance,
    )

    XCTAssertEqual(batched.layout.cells, sequential.layout.cells)
    XCTAssertEqual(batched.layout.rowLayouts.map(\.parts), sequential.layout.rowLayouts.map(\.parts))
    XCTAssertEqual(dirtyRectangles.count, updates.count)
  }

  func testUnchangedLineUpdatesDoNotInvalidateGrid() {
    let font = Font()
    let appearance = Appearance()
    var grid = Grid(
      id: Grid.OuterID,
      size: .init(columnsCount: 12, rowsCount: 4),
      font: font,
      appearance: appearance,
    )
    let cells = [
      Cell(character: "a", isDoubleWidth: false, highlightID: 1),
      Cell(character: "b", isDoubleWidth: false, highlightID: 1),
    ]
    _ = grid.applyLineUpdate(
      originColumn: 4,
      cells: cells,
      row: 3,
      font: font,
      appearance: appearance,
    )

    let dirtyRectangles = grid.applyLineUpdates(
      [.init(originColumn: 4, cells: cells, row: 3)],
      font: font,
      appearance: appearance,
    )

    XCTAssertTrue(dirtyRectangles.isEmpty)
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
      ["grid_line"] + (0 ..< rowsCount).flatMap { row in
        [
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
              .init(text: " ", highlightID: 0, repeatCount: 16),
            ]),
            false,
          ]),
          .array([
            .integer(1),
            .integer(row),
            .integer(columnsCount / 2),
            .cellRuns([
              .init(text: "x", highlightID: 5, repeatCount: 40),
              .init(text: " ", highlightID: 0, repeatCount: 40),
            ]),
            false,
          ]),
        ]
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
