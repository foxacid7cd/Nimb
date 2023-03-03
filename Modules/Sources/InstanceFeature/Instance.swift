// SPDX-License-Identifier: MIT

import AppKit
import AsyncAlgorithms
import CasePaths
import ComposableArchitecture
import Dependencies
import IdentifiedCollections
import Library
import MessagePack
import Neovim
import OSLog
import Overture
import Tagged

public struct Instance: ReducerProtocol {
  public init() {}

  public enum Action: Sendable {
    case bindNeovimProcess(
      mouseEvents: AsyncStream<MouseEvent>,
      keyPresses: AsyncStream<KeyPress>
    )
    case applyUIEventsBatch([UIEvent])
    case restartCursorBlinking
    case setCursorBlinkingPhase(Bool)
    case instanceView(action: InstanceView.Action)
  }

  public func reduce(into state: inout InstanceState, action: Action) -> EffectTask<Action> {
    let process = state.process

    switch action {
    case let .bindNeovimProcess(mouseEvents, keyPresses):
      let applyUIEventBatches = EffectTask<Action>.run { send in
        for try await value in await process.api.uiEventBatches {
          guard !Task.isCancelled else {
            return
          }
          await send(.applyUIEventsBatch(value))
        }
      }

      let reportKeyPresses = EffectTask<Action>.run { _ in
        for await keyPress in keyPresses {
          guard !Task.isCancelled else {
            return
          }

          do {
            try await process.api.nvimInputFast(
              keys: keyPress.makeNvimKeyCode()
            )

          } catch {
            assertionFailure("\(error)")
          }
        }
      }

      let reportMouseEvents = EffectTask<Action>.run { _ in
        for await mouseEvent in mouseEvents {
          guard !Task.isCancelled else {
            return
          }

          let rawButton: String
          let rawAction: String

          switch mouseEvent.content {
          case let .mouse(button, action):
            rawButton = button.rawValue
            rawAction = action.rawValue

          case let .scrollWheel(direction):
            rawButton = "wheel"
            rawAction = direction.rawValue
          }

          do {
            try await process.api.nvimInputMouseFast(
              button: rawButton,
              action: rawAction,
              modifier: "",
              grid: mouseEvent.gridID.rawValue,
              row: mouseEvent.point.row,
              col: mouseEvent.point.column
            )
          } catch {
            assertionFailure("\(error)")
          }
        }
      }

      let requestUIAttach = EffectTask<Action>.run { _ in
        do {
          let uiOptions: UIOptions = [
            .extMultigrid,
            .extHlstate,
            .extCmdline,
            .extMessages,
            .extPopupmenu,
            .extTabline,
          ]

          try await process.api.nvimUIAttachFast(
            width: 200,
            height: 60,
            options: uiOptions.nvimUIAttachOptions
          )

        } catch {
          assertionFailure("\(error)")
        }
      }

      let bindProcess = EffectTask<Action>.merge(
        applyUIEventBatches,
        requestUIAttach
          .concatenate(
            with: .merge(
              reportKeyPresses,
              reportMouseEvents
            )
          )
      )
      .cancellable(id: EffectID.bindProcess)

      return .concatenate(
        .cancel(id: EffectID.bindProcess),
        bindProcess
      )

    case .restartCursorBlinking:
      state.cursorBlinkingPhase = true

      let cancelPreviousTask = EffectTask<Action>.cancel(id: EffectID.cursorBlinking)

      guard state.cursor != nil, let modeInfo = state.modeInfo, let mode = state.mode else {
        return cancelPreviousTask
      }
      let cursorStyle = modeInfo.cursorStyles[mode.cursorStyleIndex]

      guard
        let blinkWait = cursorStyle.blinkWait, blinkWait > 0,
        let blinkOff = cursorStyle.blinkOff, blinkOff > 0,
        let blinkOn = cursorStyle.blinkOn, blinkOn > 0
      else {
        return cancelPreviousTask
      }

      let task = EffectTask<Action>.run { send in
        do {
          try await suspendingClock.sleep(for: .milliseconds(blinkWait))
          guard !Task.isCancelled else {
            return
          }
          await send(.setCursorBlinkingPhase(false))

          while true {
            try await suspendingClock.sleep(for: .milliseconds(blinkOff))
            guard !Task.isCancelled else {
              return
            }
            await send(.setCursorBlinkingPhase(true))

            try await suspendingClock.sleep(for: .milliseconds(blinkOn))
            guard !Task.isCancelled else {
              return
            }
            await send(.setCursorBlinkingPhase(false))
          }

        } catch {
          let isCancellation = error is CancellationError

          if !isCancellation {
            assertionFailure("\(error)")
          }
        }
      }
      .cancellable(id: EffectID.cursorBlinking)

      return .concatenate(cancelPreviousTask, task)

    case let .setCursorBlinkingPhase(value):
      state.cursorBlinkingPhase = value

      if let cursor = state.cursor, state.cmdlines.isEmpty {
        update(&state.grids[cursor.gridID]!) { grid in
          grid.updates.append(
            .init(
              origin: cursor.position,
              size: .init(columnsCount: 1, rowsCount: 1)
            )
          )
          grid.updateFlag.toggle()
        }
      }

      return .none

    case let .instanceView(action):
      switch action {
      case let .headerView(action):
        switch action {
        case let .reportSelectedTab(id):
          return .fireAndForget {
            do {
              _ = try await process.api.nvimSetCurrentTabpage(tabpage: id)
                .get()

            } catch {
              assertionFailure("\(error)")
            }
          }

        case .sideMenuButtonPressed:
          return .none
        }
      }
    }
  }

  private enum EffectID: String, Hashable {
    case bindProcess
    case cursorBlinking
  }

  @Dependency(\.suspendingClock)
  private var suspendingClock: any Clock<Duration>
}
