// Copyright © 2022 foxacid7cd. All rights reserved.

// Copyright © 2022 foxacid7cd. All rights reserved.
//
// import AsyncAlgorithms
// import Cocoa
// import IdentifiedCollections
// import Library
// import MessagePack
// import Neovim
// import Overture
// import SwiftUI
//
// class Store {
//  init() {
//    var appearance = Appearance()
//
//    let initialCellSize = appearance.cellSize
//    let initialDefaultBackgroundColor = appearance.defaultBackgroundColor()
//
//    let (sendAction, actions) = AsyncChannel<Action>.pipe()
//    self.sendAction = sendAction
//
//    Task {
//      await sendAction(.initial)
//    }
//
//    let initialStateAccumulator: (state: State, effects: Set<StateEffect>)? = nil
//
//    let states = actions
//      .reductions(into: initialStateAccumulator) { accum, action in
//        // accum?.effects.removeAll(keepingCapacity: true)
//
//        switch action {
//        case .initial:
//          let initialState = State(
//            cellSize: initialCellSize,
//            defaultBackgroundColor: initialDefaultBackgroundColor
//          )
//          accum = (
//            state: initialState,
//            effects: [.initial]
//          )
//
//        case let .uiEventBatch(batch):
//          switch batch {
//          case let .gridResize(decode):
//            for event in try decode() {
//              let size = Size(
//                width: event.width,
//                height: event.height
//              )
//
//              update(&accum!.state.grids[id: event.grid]) { grid in
//                if grid == nil {
//                  grid = .init(id: event.grid)
//                }
//
//                grid!.isHidden = event.grid != 1
//                grid!.set(size: size)
//              }
//
//              if event.grid == 1 {
//                accum!.state.outerGridSize = accum!.state.grids[id: event.grid]!.size
//                accum!.effects.insert(.outerGridSizeChanged)
//              }
//
//              accum!.state.renewArrayPosition(forGridWithID: event.grid)
//              accum!.state.currentTransactionEffects.insert(.gridsChanged)
//            }
//
//          case let .gridLine(decode):
//            for event in try decode() {
//              _ = accum!.state.grids[id: event.grid]!
//                .updateLine(
//                  origin: .init(
//                    x: event.colStart,
//                    y: event.row
//                  ),
//                  data: event.data
//                )
//            }
//
//            accum!.state.currentTransactionEffects.insert(.gridsChanged)
//
//          case let .gridScroll(decode):
//            for event in try decode() {
//              let frame = Rectangle(
//                origin: .init(
//                  x: event.left,
//                  y: event.top
//                ),
//                size: .init(
//                  width: event.right - event.left,
//                  height: event.bot - event.top
//                )
//              )
//              let delta = Point(x: event.cols, y: event.rows)
//
//              update(&accum!.state.grids[id: event.grid]!) { grid in
//                grid.offset(frame: frame, by: delta)
//              }
//            }
//
//            accum!.state.currentTransactionEffects.insert(.gridsChanged)
//
//          case let .gridCursorGoto(decode):
//            for event in try decode() {
//              accum!.state.cursor = (
//                gridID: event.grid,
//                position: Point(
//                  x: event.col,
//                  y: event.row
//                )
//              )
//            }
//
//            accum!.state.currentTransactionEffects.insert(.cursorChanged)
//
//          case let .gridClear(decode):
//            for event in try decode() {
//              accum!.state.grids[id: event.grid]!.clear()
//            }
//
//            accum!.state.currentTransactionEffects.insert(.gridsChanged)
//
//          case let .gridDestroy(decode):
//            for event in try decode() {
//              accum!.state.grids[id: event.grid]!.isHidden = true
//            }
//
//            accum!.state.currentTransactionEffects.insert(.gridsChanged)
//
//          case let .winPos(decode):
//            for event in try decode() {
//              let frame = Rectangle(
//                origin: .init(x: event.startcol, y: event.startrow),
//                size: .init(width: event.width, height: event.height)
//              )
//
//              update(&accum!.state.grids[id: event.grid]!) { grid in
//                grid.isHidden = false
//                grid.set(win: .pos(frame: frame))
//              }
//
//              accum!.state.renewArrayPosition(forGridWithID: event.grid)
//            }
//
//            accum!.state.currentTransactionEffects.insert(.gridsChanged)
//
//          case let .winFloatPos(decode):
//            for event in try decode() {
//              update(&accum!.state.grids[id: event.grid]!) { grid in
//                grid.isHidden = false
//
//                let win = State.Grid.Win.floatingPos(
//                  anchor: event.anchor,
//                  anchorGridID: event.anchorGrid,
//                  anchorPosition: .init(
//                    x: event.anchorCol,
//                    y: event.anchorRow
//                  )
//                )
//                grid.set(win: win)
//              }
//
//              accum!.state.renewArrayPosition(forGridWithID: event.grid)
//            }
//
//            accum!.state.currentTransactionEffects.insert(.gridsChanged)
//
//          case let .winClose(decode):
//            for event in try decode() {
//              update(&accum!.state.grids[id: event.grid]!) { grid in
//                grid.set(win: nil)
//                grid.isHidden = true
//              }
//
//              accum!.state.renewArrayPosition(forGridWithID: event.grid)
//            }
//
//            accum!.state.currentTransactionEffects.insert(.gridsChanged)
//
//            //          case let .defaultColorsSet(decode):
//            //            for event in try decode() {
//            //              appearance.setDefaultColors(
//            //                foregroundRGB: event.rgbFg,
//            //                backgroundRGB: event.rgbBg,
//            //                specialRGB: event.rgbSp
//            //              )
//            //            }
//            //
//            //            accum!.effects.insert(.defaultBackgroundColorChanged)
//
//            //          case let .hlAttrDefine(decode):
//            //            let events = try decode()
//            //
//            //            for event in events {
//            //              appearance.apply(
//            //                nvimAttr: event.rgbAttrs,
//            //                forHighlightWithID: event.id
//            //              )
//            //            }
//
////          case .flush:
////            if !accum!.state.currentTransactionEffects.isEmpty {
////              accum!.effects = !accum!.state.currentTransactionEffects
////
////              !accum!.state.currentTransactionEffects.removeAll(keepingCapacity: true)
////            }
//
//          default:
//            break
//          }
//        }
//      }
//      .map { $0! }
//      .filter { !$0.effects.isEmpty }
//
//    let initialViewModelAccumulator: (viewModel: ViewModel, effects: Set<ViewModelEffect>)? = nil
//
//    let viewModels = states
//      .reductions(into: initialViewModelAccumulator) { accum, value in
//        let (state, stateEffects) = value
//
//        // accum?.effects = .init()
//
//        if stateEffects.contains(.initial) {
//          accum = (
//            viewModel: ViewModel(),
//            effects: [.initial] as Set<ViewModelEffect>
//          )
//        }
//
//        if stateEffects.contains(.outerGridSizeChanged) {
//          accum!.viewModel.outerSize = state.outerGridSize * state.cellSize
//
//          accum!.effects.insert(.canvasChanged)
//        }
//
//        //        if stateEffects.contains(.gridsChanged) {
//        //          accum!.viewModel.grids = state.grids
//        //            .filter { !$0.isHidden }
//        //            .enumerated()
//        //            .map { index, grid in
//        //              let gridFrameOffset: CGPoint
//        //              if let anchorGridID = grid.anchorGridID {
//        //                gridFrameOffset = state.grids[id: anchorGridID]!.gridFrame.origin
//        //
//        //              } else {
//        //                gridFrameOffset = .init()
//        //              }
//        //
//        //              let gridFrame = CGRect(
//        //                origin: .init(
//        //                  x: grid.gridFrame.origin.x + gridFrameOffset.x,
//        //                  y: grid.gridFrame.origin.y + gridFrameOffset.y
//        //                ),
//        //                size: grid.gridFrame.size
//        //              )
//        //
//        //              let cellSize = state.cellSize
//        //              let frame = CGRect(
//        //                origin: .init(
//        //                  x: gridFrame.origin.x * cellSize.width,
//        //                  y: gridFrame.origin.y * cellSize.height
//        //                ),
//        //                size: .init(
//        //                  width: gridFrame.size.width * cellSize.width,
//        //                  height: gridFrame.size.height * cellSize.height
//        //                )
//        //              )
//        //
//        //              return .init(
//        //                id: grid.id,
//        //                index: index,
//        //                frame: frame,
//        //                rowAttributedStrings: grid.rows
//        //                  .map { row in
//        //                    var attributedString = row.attributedString
//        //                    attributedString.font = state.font
//        //
//        //                    return attributedString
//        //                  }
//        //              )
//        //            }
//        //
//        //          accum!.effects.insert(.canvasChanged)
//        //        }
//        //
//        //        if stateEffects.contains(.cursorChanged) {
//        //          if let cursor = state.cursor {
//        //            let rectangle = Rectangle(
//        //              origin: cursor.position,
//        //              size: .init(width: 1, height: 1)
//        //            )
//        //            accum!.viewModel.cursor = (
//        //              gridID: cursor.gridID,
//        //              rect: rectangle * state.cellSize
//        //            )
//        //
//        //          } else {
//        //            accum!.viewModel.cursor = nil
//        //          }
//        //
//        //          accum!.effects.insert(.canvasChanged)
//        //        }
//
////        .compactMap { accum in
////          guard let accum, !accum.effects.isEmpty else {
////            return nil
////          }
////
////          return accum
////        }
//      }
//  }
//
////  let viewModels: AsyncStream<(viewModel: ViewModel, effects: Set<ViewModelEffect>)>
//
//  func apply(_ uiEventBatch: UIEventBatch) async {
////    await sendAction(.uiEventBatch(uiEventBatch))
//  }
//
//  private enum Action {
//    case initial
//    case uiEventBatch(UIEventBatch)
//  }
//
//  private let sendAction: @Sendable (Action)
//    async -> Void
// }
