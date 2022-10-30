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
        let gridsWindowController = GridsWindowController()
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
          for model in models {
            let gridSize = GridSize(
              rowsCount: model.height,
              columnsCount: model.width
            )

            if var window = self.store.state.windows[model.grid] {
              window.grid.resize(to: gridSize, fillingEmptyWith: nil)
              self.store.state.windows[model.grid] = window

            } else {
              self.store.state.windows[model.grid] = State.Window(
                grid: .init(repeating: nil, size: gridSize),
                origin: .init(),
                anchor: .topLeft,
                isHidden: false,
                zIndex: 0,
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
          for model in models {
            self.store.state.windows[model.grid] = nil

            self.store.publish(event:
              .windowClosed(gridID: model.grid)
            )
          }

        case let .gridLine(models):
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

            self.store.state.withMutableWindowIfExists(gridID: model.grid) { window in
              window.grid.put(
                grid: window.grid.subGrid(
                  at: fromRectangle
                ),
                at: toOrigin
              )
            }

            self.store.publish(
              event: .windowGridRectangleMoved(
                gridID: model.grid,
                rectangle: fromRectangle,
                toOrigin: toOrigin
              )
            )
          }

        case let .gridClear(models):
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
          for model in models {
            self.store.state.withMutableWindowIfExists(gridID: model.grid) { window in
              window.grid.resize(
                to: .init(rowsCount: model.height, columnsCount: model.width),
                fillingEmptyWith: nil
              )
              window.origin = .init(row: model.startrow, column: model.startcol)
              window.isHidden = false
              window.zIndex = 0
              window.ref = model.win
            }

            self.store.publish(
              event: .windowFrameChanged(
                gridID: model.grid
              )
            )
          }

        case let .winFloatPos(models):
          for model in models {
            let anchorWindow = self.store.state.windows[model.anchorGrid]!
            let anchorPoint = anchorWindow.frame.origin + GridPoint(
              row: Int(model.anchorRow.doubleValue!),
              column: Int(model.anchorCol.doubleValue!)
            )

            self.store.state.withMutableWindowIfExists(gridID: model.grid) { window in
              window.origin = anchorPoint
              window.anchor = model.anchorValue
              window.isHidden = false
              window.ref = model.win
              window.zIndex = model.zindex
            }

            self.store.publish(
              event: .windowFrameChanged(gridID: model.grid)
            )
          }

        case let .winExternalPos(models):
          log(.info, "Win external pos: \(models.count)")

        case let .winHide(models):
          for model in models {
            self.store.state.withMutableWindowIfExists(gridID: model.grid) { window in
              window.isHidden = true
            }

            self.store.publish(
              event: .windowHid(gridID: model.grid)
            )
          }

        case let .winClose(models):
          for model in models {
            self.store.state.windows[model.grid] = nil

            self.store.publish(event: .windowClosed(gridID: model.grid))
          }

        case let .defaultColorsSet(models):
          for model in models {
            self.store.state.defaultHighlight = .init(
              foregroundColor: .init(hex: UInt(model.rgbFg), alpha: 1),
              backgroundColor: .init(hex: UInt(model.rgbBg), alpha: 1),
              specialColor: .init(hex: UInt(model.rgbSp), alpha: 1)
            )
          }

          self.store.publish(event: .highlightChanged)

        case let .hlAttrDefine(models):
          for model in models {
            self.store.state.withMutableHighlight(id: model.id) { highlight in
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
            }
          }

          self.store.publish(event: .highlightChanged)

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
