//
//  AppDelegate.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import API
import AppKit
import CasePaths
import Library
import RxCocoa
import RxSwift
import XPC

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: AppKit.Notification) {
    // self.startNvimProcess()

    let connection = xpc_connection_create("\(Bundle.main.bundleIdentifier!).Agent", .main)
    self.xpcConnection = connection

    xpc_connection_set_event_handler(connection) { object in
      log(.info, "Received xpc object: \(object)")
    }

    xpc_connection_activate(connection)
  }

  func applicationWillTerminate(_ notification: AppKit.Notification) {
    self.nvimProcess?.terminate()
  }

  @IBOutlet private var mainMenu: NSMenu!

  private var nvimProcess: NvimProcess?
  private var gridsWindowController: GridsWindowController?
  private let inputSubject = PublishSubject<Input>()
  // @MainActor
  // private var state = State()
  private var changeStateTask: Task<State, Never>?
  private var xpcConnection: xpc_connection_t?

  @MainActor
  private func startNvimProcess() {
    let nvimBundleURL = Bundle.main.url(forResource: "nvim", withExtension: "bundle")!
    let nvimBundle = Bundle(url: nvimBundleURL)!

    let nvimProcess = NvimProcess(
      executableURL: nvimBundle.url(forAuxiliaryExecutable: "nvim")!,
      runtimeURL: nvimBundle.resourceURL!.appendingPathComponent("runtime")
    )
    self.nvimProcess = nvimProcess

    Task {
      do {
        for try await notifications in nvimProcess.notifications {
          self.handle(notifications: notifications)
        }

      } catch {
        self.terminate(
          with: "Failed receiving notifications"
            .fail(child: error.fail())
        )
      }
    }

    Task {
      for try await error in nvimProcess.error {
        self.terminate(
          with: "Nvim process emmited error"
            .fail(child: error.fail())
        )
      }
    }

    nvimProcess.run()

    Task {
      try await Task.sleep(nanoseconds: NSEC_PER_SEC)

      do {
        try await nvimProcess.nvimUIAttach(
          width: 150,
          height: 40,
          options: [
            UIOption.extMultigrid.value: true,
            UIOption.extHlstate.value: true,
            UIOption.extMessages.value: true
          ]
        )

      } catch {
        "Failed to attach nvim UI"
          .fail(child: error.fail())
          .assertionFailure()
      }
    }
  }

  @MainActor
  private func handle(notifications: [NvimNotification]) {
    var currentBatch = [UIEvent]()

    for notification in notifications {
      switch notification {
      case let .redraw(uiEvents):
        for uiEvent in uiEvents {
          currentBatch.append(uiEvent)

          switch uiEvent {
          case .flush:
            if !currentBatch.isEmpty {
              self.changeState(with: currentBatch)
              currentBatch = []
            }

          default:
            break
          }
        }
      }
    }

    if !currentBatch.isEmpty {
      self.changeState(with: currentBatch)
    }
  }

  @MainActor
  private func changeState(with uiEvents: [UIEvent]) {
    let previousTask = self.changeStateTask

    self.changeStateTask = Task<State, Never> {
      var state = await previousTask?.value ?? State()

      var events = [Event]()

      for uiEvent in uiEvents {
        do {
          let (newState, newEvents) = try await Task {
            var state = state
            let events = try state.apply(uiEvent: uiEvent)
            return (state, events)
          }
          .value

          state = newState
          events += newEvents

        } catch {
          self.terminate(
            with: "Change state error"
              .fail(child: error.fail())
          )
        }
      }

      await self.handle(state: state, events: events)

      let appearanceChanged = events.contains(where: { event in
        switch event {
        case .appearanceChanged:
          return true

        default:
          return false
        }
      })
      if appearanceChanged {
        state.fontDerivatives.glyphRunCache.removeAll()
      }

      return state
    }
  }

  @MainActor
  private func handle(state: State, events: [Event]) async {
    if let gridsWindowController = self.gridsWindowController {
      await gridsWindowController.handle(state: state, events: events)

    } else {
      let gridsWindowController = GridsWindowController(state: state)
      self.gridsWindowController = gridsWindowController

      self <~ gridsWindowController.input
        .bind(with: self) { $0.nvimProcess?.register(input: $1) }

      gridsWindowController.showWindow(nil)
    }
  }

  @MainActor
  private func terminate(with error: Error) {
    let alert = NSAlert()
    alert.messageText = "Nvim process failed"
    alert.informativeText = error.alertMessage
    alert.addButton(withTitle: "Close")
    alert.runModal()

    NSApplication.shared.terminate(nil)
  }
}

private extension Error {
  var alertMessage: String {
    if let fail = self as? Fail {
      return [
        fail.logMessage,
        fail.logChildren
          .map { ($0 as? Error)?.alertMessage ?? String(describing: $0) }
          .joined(separator: "\n")
      ]
      .joined(separator: "\n")
    }

    return String(describing: self)
  }
}

private extension State {
  mutating func apply(uiEvent: UIEvent) throws -> [Event] {
    var events = [Event]()

    switch uiEvent {
    case let .gridResize(models):
      for model in models {
        let gridSize = GridSize(
          rowsCount: model.height,
          columnsCount: model.width
        )

        if var window = self.windows[model.grid] {
          window.grid.resize(to: gridSize, fillingEmptyWith: nil)
          self.windows[model.grid] = window

        } else {
          self.windows[model.grid] = State.Window(
            grid: .init(repeating: nil, size: gridSize),
            origin: .init(),
            anchor: .topLeft,
            isHidden: false,
            zIndex: 0,
            ref: nil
          )
        }

        events.append(
          .grid(id: model.grid, model: .windowFrameChanged)
        )
      }

    case let .gridDestroy(models):
      for model in models {
        self.windows[model.grid] = nil

        events.append(
          .grid(id: model.grid, model: .windowClosed)
        )
      }

    case let .gridLine(models):
      var latestHlID: Int?
      var latestRow: Int?

      for model in models {
        var updatedCellsCount = 0

        for messagePackValue in model.data {
          guard var arrayValue = messagePackValue.arrayValue else {
            throw "Cell data is not an array".fail()
          }

          guard !arrayValue.isEmpty, let text = arrayValue.removeFirst().stringValue else {
            throw "Expected cell text is not a string".fail()
          }
          if text.count > 1 {
            throw "Cell text \(text) has more than one character".fail()
          }
          let character = text.first

          var repeatCount = 1

          if !arrayValue.isEmpty {
            guard let hlID = arrayValue.removeFirst().uintValue else {
              throw "Expected cell hl_id is not an unsigned integer".fail()
            }
            latestHlID = Int(hlID)

            if !arrayValue.isEmpty {
              guard let parsedRepeatCount = arrayValue.removeFirst().uintValue else {
                throw "Expected cell repeat count is not an unsigned integer".fail()
              }
              repeatCount = Int(parsedRepeatCount)
            }
          }

          guard let latestHlID else {
            throw "At least one hlID had to be parsed".fail()
          }

          if latestRow != model.row {
            updatedCellsCount = 0
          }

          for repeatIndex in 0 ..< repeatCount {
            let index = GridPoint(
              row: model.row,
              column: model.colStart + updatedCellsCount + repeatIndex
            )
            self.windows[model.grid]?.grid[index] = Cell(
              character: character,
              hlID: latestHlID
            )
          }

          events.append(
            .grid(
              id: model.grid,
              model: .windowGridRowChanged(
                origin: .init(
                  row: model.row,
                  column: model.colStart + updatedCellsCount
                ),
                columnsCount: repeatCount
              )
            )
          )
          updatedCellsCount += repeatCount

          latestRow = model.row
        }
      }

    case let .gridScroll(models):
      for model in models {
        let originRow = model.top
        let rowsCount = model.bot - model.top
        let delta = model.rows

        self.withMutableWindowIfExists(gridID: model.grid) { window in
          guard model.right - model.left == window.grid.size.columnsCount else {
            "Full width vertical scroll expected, but got something different"
              .fail()
              .fatalError()
          }

          window.grid.moveRows(
            originRow: originRow,
            rowsCount: rowsCount,
            delta: delta
          )
        }

        events.append(
          .grid(
            id: model.grid,
            model: .windowGridRowsMoved(
              originRow: originRow,
              rowsCount: rowsCount,
              delta: delta
            )
          )
        )
      }

    case let .gridClear(models):
      for model in models {
        self.withMutableWindowIfExists(gridID: model.grid) { window in
          window.grid = .init(
            repeating: nil,
            size: window.grid.size
          )
        }

        events.append(
          .grid(
            id: model.grid,
            model: .windowGridCleared
          )
        )
      }

    case let .gridCursorGoto(models):
      for model in models {
        let previousCursor = self.cursor

        self.cursor = State.Cursor(
          gridID: model.grid,
          position: .init(
            row: model.row,
            column: model.col
          )
        )

        events.append(.cursor(previousCusor: previousCursor))
      }

    case let .winPos(models):
      for model in models {
        self.withMutableWindowIfExists(gridID: model.grid) { window in
          window.grid.resize(
            to: .init(rowsCount: model.height, columnsCount: model.width),
            fillingEmptyWith: nil
          )
          window.origin = .init(row: model.startrow, column: model.startcol)
          window.isHidden = false
          window.zIndex = 0
          window.ref = model.win
        }

        events.append(
          .grid(id: model.grid, model: .windowFrameChanged)
        )
      }

    case let .winFloatPos(models):
      for model in models {
        let anchorWindow = self.windows[model.anchorGrid]!
        let anchorPoint = anchorWindow.frame.origin + GridPoint(
          row: Int(model.anchorRow.doubleValue!),
          column: Int(model.anchorCol.doubleValue!)
        )

        self.withMutableWindowIfExists(gridID: model.grid) { window in
          window.origin = anchorPoint
          window.anchor = model.anchorValue
          window.isHidden = false
          window.ref = model.win
          window.zIndex = model.zindex
        }

        events.append(
          .grid(id: model.grid, model: .windowFrameChanged)
        )
      }

    case let .winExternalPos(models):
      log(.info, "Win external pos: \(models.count)")

    case let .winHide(models):
      for model in models {
        self.withMutableWindowIfExists(gridID: model.grid) { window in
          window.isHidden = true
        }

        events.append(
          .grid(id: model.grid, model: .windowHid)
        )
      }

    case let .winClose(models):
      for model in models {
        self.windows[model.grid] = nil

        events.append(
          .grid(id: model.grid, model: .windowClosed)
        )
      }

    case let .defaultColorsSet(models):
      for model in models {
        self.defaultHighlight = .init(
          foregroundColor: .init(hex: UInt(model.rgbFg), alpha: 1),
          backgroundColor: .init(hex: UInt(model.rgbBg), alpha: 1),
          specialColor: .init(hex: UInt(model.rgbSp), alpha: 1)
        )
      }

      events.append(.appearanceChanged)

    case let .hlAttrDefine(models):
      for model in models {
        self.withMutableHighlight(id: model.id) { highlight in
          if let hex = model.rgbAttrs[.string("foreground")]?.uintValue {
            highlight.foregroundColor = .init(hex: hex, alpha: 1)
          }

          if let hex = model.rgbAttrs[.string("background")]?.uintValue {
            highlight.backgroundColor = .init(hex: hex, alpha: 1)
          }

          if let hex = model.rgbAttrs[.string("special")]?.uintValue {
            highlight.specialColor = .init(hex: hex, alpha: 1)
          }

          if let reverse = model.rgbAttrs[.string("reverse")]?.boolValue {
            highlight.reverse = reverse
          }

          if let blend = model.rgbAttrs[.string("blend")]?.uintValue {
            highlight.blend = Int(blend)
          }

          if let italic = model.rgbAttrs[.string("italic")]?.boolValue {
            highlight.italic = italic
          }

          if let bold = model.rgbAttrs[.string("bold")]?.boolValue {
            highlight.bold = bold
          }
        }
      }

      events.append(.appearanceChanged)

    case .flush:
      events.append(.flushRequested)

    default:
      break
    }

    return events
  }
}
