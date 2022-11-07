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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, EventListener {
  func applicationDidFinishLaunching(_ notification: AppKit.Notification) {
    self.listen()
    self.startNvimProcess()
  }

  func applicationWillTerminate(_ notification: AppKit.Notification) {
    self.nvimProcess?.terminate()
  }

  func published(events: [Event]) {
    for event in events {
      switch event {
      case .windowFrameChanged:
        if self.gridsWindowController == nil {
          let gridsWindowController = GridsWindowController()
          self.gridsWindowController = gridsWindowController

          self <~ gridsWindowController.input
            .bind(onNext: self.inputSubject.onNext(_:))

          gridsWindowController.showWindow(nil)
        }

      default:
        break
      }
    }
  }

  @IBOutlet private var mainMenu: NSMenu!

  private let inputSubject = PublishSubject<Input>()
  private var nvimProcess: NvimProcess?
  private var gridsWindowController: GridsWindowController?

  @MainActor
  private func startNvimProcess() {
    let nvimBundleURL = Bundle.main.url(forResource: "nvim", withExtension: "bundle")!
    let nvimBundle = Bundle(url: nvimBundleURL)!

    let input = self.inputSubject
      .throttle(.milliseconds(50), latest: true, scheduler: SerialDispatchQueueScheduler(qos: .userInteractive))

    let nvimProcess = NvimProcess(
      input: input,
      executableURL: nvimBundle.url(forAuxiliaryExecutable: "nvim")!,
      runtimeURL: nvimBundle.resourceURL!.appendingPathComponent("runtime")
    )

    self <~ nvimProcess.run()
      .flatMap { Observable.from($0, scheduler: MainScheduler.instance) }
      .map { try self.store.state.apply(notification: $0) }
      /* .flatMap { notification -> Observable<Event> in
         Observable.create { observer in
           DispatchQueue.main.async {
             observer.onNext(self.store.state)
             observer.onCompleted()
           }

           return Disposables.create()
         }
         .flatMap { state in
           var state = state
           let events = try state.apply(notification: notification)
           DispatchQueue.main.async {
             self.store.state = state
           }
           return Observable.from(events)
         }
       } */
      .buffer(timeSpan: .milliseconds(20), count: 200, scheduler: MainScheduler.instance)
      .filter { !$0.isEmpty }
      .catch { error in
        let alert = NSAlert()
        alert.messageText = "Nvim process failed"
        alert.informativeText = error.alertMessage
        alert.addButton(withTitle: "Close")
        alert.runModal()

        NSApplication.shared.terminate(nil)

        return .empty()
      }
      .bind(onNext: { eventsBatches in
        var allEvents = [Event]()
        var flushedGridIDs: Set<Int>? = .init()

        for (events, affectedGridIDs, hasFlush) in eventsBatches {
          allEvents += events

          if let affectedGridIDs {
            if hasFlush {
              flushedGridIDs?.formUnion(affectedGridIDs)
            }

          } else {
            flushedGridIDs = nil
          }
        }

        if let flushedGridIDs {
          if !flushedGridIDs.isEmpty {
            allEvents.append(.flushRequested(gridIDs: flushedGridIDs))
          }

        } else {
          allEvents.append(.flushRequested(gridIDs: nil))
        }

        self.store.publish(events: allEvents)
      })

    DispatchQueues.Nvim.dispatchQueue.asyncAfter(deadline: .now() + .milliseconds(200)) {
      Task {
        do {
          try await nvimProcess.nvimUIAttach(
            width: self.store.state.outerGridSize.columnsCount,
            height: self.store.state.outerGridSize.rowsCount,
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
  }
}

extension Reactive where Base: EventListener, Base: AnyObject {
  func events(_ events: Observable<[Event]>) -> Disposable {
    events.bind(with: base) { base, events in
      base.published(events: events)
    }
  }
}

protocol EventListener {
  func published(events: [Event])
}

extension EventListener {
  var store: Store {
    .shared
  }
}

extension EventListener where Self: NSObject {
  func listen() {
    self <~ Store.shared.events
      .bind(to: self.rx.events(_:))
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
  mutating func apply(notification: NvimNotification) throws -> (events: [Event], affectedGridIDs: Set<Int>?, hasFlush: Bool) {
    var events = [Event]()
    var affectedGridIDs: Set<Int>? = .init()
    var hasFlush = false

    switch notification {
    case let .redraw(uiEvents):
      for uiEvent in uiEvents {
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
              .windowFrameChanged(
                gridID: model.grid
              )
            )
            affectedGridIDs?.insert(model.grid)
          }

        case let .gridDestroy(models):
          for model in models {
            self.windows[model.grid] = nil

            events.append(
              .windowClosed(gridID: model.grid)
            )
            affectedGridIDs?.insert(model.grid)
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
                .windowGridRowChanged(
                  gridID: model.grid,
                  origin: .init(
                    row: model.row,
                    column: model.colStart + updatedCellsCount
                  ),
                  columnsCount: repeatCount
                )
              )
              affectedGridIDs?.insert(model.grid)
              updatedCellsCount += repeatCount

              latestRow = model.row
            }
          }

        case let .gridScroll(models):
          for model in models {
            let size = GridSize(
              rowsCount: model.bot - model.top,
              columnsCount: model.right - model.left
            )
            let fromOrigin = GridPoint(
              row: model.top,
              column: model.left
            )
            let fromRectangle = GridRectangle(origin: fromOrigin, size: size)
            let toOrigin = fromOrigin - GridPoint(row: model.rows, column: model.cols)

            self.withMutableWindowIfExists(gridID: model.grid) { window in
              window.grid.put(
                grid: window.grid.subGrid(
                  at: fromRectangle
                ),
                at: toOrigin
              )
            }

            events.append(
              .windowGridRectangleMoved(
                gridID: model.grid,
                rectangle: fromRectangle,
                toOrigin: toOrigin
              )
            )
            affectedGridIDs?.insert(model.grid)
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
              .windowGridCleared(gridID: model.grid)
            )
            affectedGridIDs?.insert(model.grid)
          }

        case let .gridCursorGoto(models):
          for model in models {
            if let previousCursor = self.cursor {
              events.append(.cursor(gridID: previousCursor.gridID, position: nil))
              affectedGridIDs?.insert(previousCursor.gridID)
            }

            let cursor = State.Cursor(
              gridID: model.grid,
              position: .init(
                row: model.row,
                column: model.col
              )
            )
            self.cursor = cursor

            events.append(.cursor(gridID: cursor.gridID, position: cursor.position))
            affectedGridIDs?.insert(model.grid)
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
              .windowFrameChanged(
                gridID: model.grid
              )
            )
            affectedGridIDs?.insert(model.grid)
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
              .windowFrameChanged(gridID: model.grid)
            )
            affectedGridIDs?.insert(model.grid)
          }

        case let .winExternalPos(models):
          log(.info, "Win external pos: \(models.count)")

        case let .winHide(models):
          for model in models {
            self.withMutableWindowIfExists(gridID: model.grid) { window in
              window.isHidden = true
            }

            events.append(
              .windowHid(gridID: model.grid)
            )
            affectedGridIDs?.insert(model.grid)
          }

        case let .winClose(models):
          for model in models {
            self.windows[model.grid] = nil

            events.append(.windowClosed(gridID: model.grid))
            affectedGridIDs?.insert(model.grid)
          }

        case let .defaultColorsSet(models):
          for model in models {
            self.defaultHighlight = .init(
              foregroundColor: .init(hex: UInt(model.rgbFg), alpha: 1),
              backgroundColor: .init(hex: UInt(model.rgbBg), alpha: 1),
              specialColor: .init(hex: UInt(model.rgbSp), alpha: 1)
            )
          }

          events.append(.highlightChanged)
          affectedGridIDs = nil

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

          events.append(.highlightChanged)
          affectedGridIDs = nil

        case .flush:
          hasFlush = true

        default:
          break
        }
      }
    }

    return (events, affectedGridIDs, hasFlush)
  }
}
