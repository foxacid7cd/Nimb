//
//  AppDelegate.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import CasePaths
import Library
import Nvim
import RxCocoa
import RxSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, EventListener {
  func applicationDidFinishLaunching(_ notification: AppKit.Notification) {
    self.listen()
    self.startNvimProcess()
  }

  func published(event: Event) {
    switch event {
    case .windowFrameChanged:
      if self.gridsWindowController == nil {
        let gridsWindowController = GridsWindowController(
          glyphRunsCache: self.glyphRunsCache
        )
        self.gridsWindowController = gridsWindowController

        self <~ gridsWindowController.keyDown
          .map(KeyPress.init)
          .bind(onNext: self.inputSubject.onNext(_:))

        gridsWindowController.showWindow(nil)
      }

    default:
      break
    }
  }

  @IBOutlet private var mainMenu: NSMenu!

  private let glyphRunsCache = Cache<String, [GlyphRun]>(
    dispatchQueue: DispatchQueues.GlyphRunsCache
  )
  private let inputSubject = PublishSubject<KeyPress>()
  private var nvimProcess: NvimProcess?
  private var gridsWindowController: GridsWindowController?

  @MainActor
  private func startNvimProcess() {
    let nvimProcess = NvimProcess(input: self.inputSubject)
    self.nvimProcess = nvimProcess

    self <~ nvimProcess.notifications
      .bind(with: self) {
        do {
          try $0.handle(notification: $1)

        } catch {
          "nvim process notification failed"
            .fail(child: error.fail())
            .assertionFailure()
        }
      }

    do {
      try nvimProcess.run()

    } catch {
      "Failed running nvim process"
        .fail(child: error.fail())
        .log()
    }

    Task {
      do {
        try await nvimProcess.nvimUIAttach(
          width: store.state.outerGridSize.columnsCount,
          height: store.state.outerGridSize.rowsCount,
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
  private func handle(notification: NvimNotification) throws {
    switch notification {
    case let .redraw(uiEvents):
      for uiEvent in uiEvents {
        switch uiEvent {
        case let .gridResize(models):
          log(.info, "Grid resize: \(models.count)")

          for model in models {
            log(.info, "grid resize: \(model)")

            let gridSize = GridSize(
              rowsCount: model.height,
              columnsCount: model.width
            )

            if var window = self.store.state.windows[model.grid] {
              window.grid.resize(to: gridSize, fillingEmptyWith: nil)
              window.frame.size = .init(
                rowsCount: min(gridSize.rowsCount, window.grid.size.rowsCount),
                columnsCount: min(gridSize.columnsCount, window.grid.size.columnsCount)
              )
              self.store.state.windows[model.grid] = window

            } else {
              self.store.state.windows[model.grid] = State.Window(
                grid: .init(repeating: nil, size: gridSize),
                frame: .init(size: gridSize),
                isHidden: false,
                ref: nil
              )
            }

            self.store.publish(
              event: .windowFrameChanged(
                gridID: model.grid
              )
            )
          }

        case let .gridDestroy(models):
          log(.info, "Grid destroy: \(models.count)")

          for model in models {
            self.store.state.windows[model.grid] = nil

            self.store.publish(event:
              .windowClosed(gridID: model.grid)
            )
          }

        case let .gridLine(models):
          log(.info, "Grid line: \(models.count)")

          var latestHlID: Int?
          var latestRow: Int?

          var events = [Event]()

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
                self.store.state.windows[model.grid]!.grid[index] = Cell(
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
              updatedCellsCount += repeatCount

              latestRow = model.row
            }
          }

          self.store.publish(events: events)

        case let .gridScroll(models):
          log(.info, "Grid scroll: \(models.count)")

          for model in models {
            let size = GridSize(
              rowsCount: model.bot - model.top,
              columnsCount: model.right - model.left
            )
            let fromOrigin = GridPoint(
              row: model.top,
              column: model.left
            )
            let toOrigin = fromOrigin - GridPoint(row: model.rows, column: model.cols)

            self.store.state.withMutableWindowIfExists(gridID: model.grid) { window in
              window.grid.put(
                grid: window.grid.subGrid(
                  at: .init(origin: fromOrigin, size: size)
                ),
                at: toOrigin
              )
            }

            let toRectangle = GridRectangle(
              origin: toOrigin,
              size: size
            )
            .intersection(
              .init(
                origin: .init(),
                size: size
              )
            )

            if let toRectangle {
              self.store.publish(
                event: .windowGridRectangleChanged(
                  gridID: model.grid,
                  rectangle: toRectangle
                )
              )
            }
          }

        case let .gridClear(models):
          log(.info, "Grid clear: \(models.count)")

          for model in models {
            self.store.state.withMutableWindowIfExists(gridID: model.grid) { window in
              window.grid = .init(
                repeating: nil,
                size: window.grid.size
              )
            }

            self.store.publish(
              event: .windowGridCleared(gridID: model.grid)
            )
          }

        case let .gridCursorGoto(models):
          log(.info, "Grid cursor goto: \(models.count)")

          for model in models {
            let previousCursor = self.store.state.cursor

            self.store.state.cursor = .init(
              gridID: model.grid,
              position: .init(
                row: model.row,
                column: model.col
              )
            )

            self.store.publish(
              event: .cursorMoved(
                previousCursor: previousCursor
              )
            )
          }

        case let .winPos(models):
          log(.info, "Win pos: \(models.count)")

          for model in models {
            log(.info, "win pos: \(model)")

            self.store.state.withMutableWindowIfExists(gridID: model.grid) { window in
              window.frame = .init(
                origin: .init(row: model.startrow, column: model.startcol),
                size: .init(rowsCount: model.height, columnsCount: model.width)
              )
              window.ref = model.win
            }

            self.store.publish(
              event: .windowFrameChanged(
                gridID: model.grid
              )
            )
          }

        case let .winFloatPos(models):
          log(.info, "Win float pos: \(models.count)")

//          for model in models {
//            self.store.state.windows[model.grid] = .init(
//              grid: .init(
//                repeating: nil,
//                size: self.store.state.outerGridSize
//              ),
//              origin: .init(),
//              isHidden: true
//            )
//
//            self.store.publish(
//              event: .windowFrameChanged(gridID: model.grid)
//            )
//          }

        case let .winExternalPos(models):
          log(.info, "Win external pos: \(models.count)")

//          for model in models {
//            self.store.state.windows[model.grid] = .init(
//              grid: .init(
//                repeating: nil,
//                size: self.store.state.outerGridSize
//              ),
//              isHidden: true,
//              frame: nil
//            )
//
//            self.store.publish(
//              event: .windowFrameChanged(gridID: model.grid)
//            )
//          }

        case let .winHide(models):
          log(.info, "Win hide: \(models.count)")

          for model in models {
            self.store.state.withMutableWindowIfExists(gridID: model.grid) { window in
              window.isHidden = true
            }

            self.store.publish(
              event: .windowHid(gridID: model.grid)
            )
          }

        case let .winClose(models):
          log(.info, "Win close: \(models.count)")

          for model in models {
            self.store.state.windows[model.grid] = nil

            self.store.publish(event: .windowClosed(gridID: model.grid))
          }

        case .flush:
          self.store.publish(event: .flushRequested)

        default:
          break
        }
      }
    }
  }
}

extension Reactive where Base: EventListener, Base: AnyObject {
  func events(_ events: Observable<[Event]>) -> Disposable {
    events.bind(with: base) { base, events in
      for event in events {
        base.published(event: event)
      }
    }
  }
}

protocol EventListener {
  func published(event: Event)
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
