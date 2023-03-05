// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import Neovim

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var instance: Instance?
  private var mainWindowController: MainWindowController?

  func applicationDidFinishLaunching(_: Notification) {
    setupNeovimInstance()
    showMainWindowController()
    setupKeyDownLocalMonitor()
  }

  private func setupNeovimInstance() {
    instance = Instance()

    Task {
      for await updates in instance!.stateUpdatesStream() {
        let state = instance!.state

        if updates.isTitleUpdated {
          customDump(state.title)
        }
      }
    }

    Task {
      let finishedResult = await instance!.finishedResult()
      customDump(finishedResult)
    }
  }

  private func showMainWindowController() {
    let mainViewController = MainViewController()

    mainWindowController = MainWindowController(viewController: mainViewController)
    mainWindowController!.showWindow(nil)
  }

  private func setupKeyDownLocalMonitor() {
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      if event.modifierFlags.contains(.command) {
        return event
      }

      let keyPress = KeyPress(event: event)
      let instance = self.instance!

      Task {
        await instance.report(keyPress: keyPress)
      }

      return nil
    }
  }
}

//  func bind(font: NimsFont, instance: Instance) {
//    cancellables.forEach { $0.cancel() }
//    cancellables.removeAll(keepingCapacity: true)
//
//    bindMsgShowsWindow(font: font, instance: instance)
//    bindCmdlinesWindow(font: font, instance: instance)
//  }
//
//  @MainActor
//  private func bindMsgShowsWindow(font: NimsFont, instance: Instance) {
//    let viewController = NSHostingController<MsgShowsView>(
//      rootView: .init(font: font, instance: instance)
//    )
//    viewController.sizingOptions = .preferredContentSize
//
//    let window = Window(contentViewController: viewController)
//    window.styleMask = [.borderless, .utilityWindow]
//    window.isMovableByWindowBackground = true
//    window.isOpaque = false
//    window.backgroundColor = .clear
//    window.setFrameOrigin(.init(x: 1200, y: 200))
////
////    instance.objectWillChange.
////    state.publisher
////      .removeDuplicates(by: { lhs, rhs in
////        guard
////          lhs.msgShowsUpdateFlag == rhs.msgShowsUpdateFlag,
////          lhs.appearanceUpdateFlag == rhs.appearanceUpdateFlag
////        else {
////          return false
////        }
////
////        return true
////      })
////      .sink { state in
////        customDump(state.msgShows)
////
////        if !state.msgShows.isEmpty {
////          window.setIsVisible(true)
////          window.orderFront(nil)
////
////        } else {
////          window.setIsVisible(false)
////        }
////      }
////      .store(in: &cancellables)
//  }
//
//  @MainActor
//  private func bindCmdlinesWindow(font: NimsFont, instance: Instance) {
//    let viewController = NSHostingController<CmdlinesView>(
//      rootView: .init(font: font, instance: instance)
//    )
//    viewController.sizingOptions = .preferredContentSize
//
//    let window = Window(contentViewController: viewController)
//    window.styleMask = [.borderless, .utilityWindow]
//    window.isMovableByWindowBackground = true
//    window.isOpaque = false
//    window.backgroundColor = .clear
//    window.level = .floating
//    window.setFrameOrigin(.init(x: 200, y: 200))
////
////    state.publisher
////      .sink { state in
////        if !state.cmdlines.isEmpty {
////          window.setIsVisible(true)
////          window.orderFront(nil)
////
////        } else {
////          window.setIsVisible(false)
////        }
////      }
////      .store(in: &cancellables)
//  }
// }
//
// private final class Window: NSPanel {
//  override var canBecomeKey: Bool {
//    false
//  }
// }
//
// struct MsgShowsView: View {
//  var font: NimsFont
//  var instance: Instance
//
//  var body: some View {
//    Text(makeContentAttributedString())
//      .lineLimit(nil)
//      .padding(
//        .init(
//          top: font.cellHeight,
//          leading: font.cellWidth * 2.5,
//          bottom: font.cellHeight,
//          trailing: font.cellWidth * 2.5
//        )
//      )
//      .background {
//        let rectangle = Rectangle()
//
//        rectangle
//          .fill(
//            instance.state.appearance.defaultBackgroundColor.swiftUI.opacity(0.9)
//          )
//
//        rectangle
//          .stroke(
//            instance.state.appearance.defaultForegroundColor.swiftUI.opacity(0.1),
//            lineWidth: 1
//          )
//      }
//  }
//
//  @MainActor
//  private func makeContentAttributedString() -> AttributedString {
//    var accumulator = AttributedString()
//
//    for (index, msgShow) in instance.state.msgShows.values.enumerated() {
//      msgShow.contentParts
//        .map { contentPart -> AttributedString in
//          AttributedString(
//            contentPart.text,
//            attributes: .init([
//              .font: font.nsFont(),
//              .foregroundColor: instance.state.appearance.foregroundColor(for: contentPart.highlightID).swiftUI,
//              .backgroundColor: contentPart.highlightID.isDefault ? SwiftUI.Color.clear : instance.state.appearance.backgroundColor(for: contentPart.highlightID).swiftUI,
//            ])
//          )
//        }
//        .forEach { accumulator.append($0) }
//
//      if index < instance.state.msgShows.count - 1 {
//        accumulator.append("\n" as AttributedString)
//      }
//    }
//
//    return accumulator
//  }
// }
//
// struct CmdlinesView: View {
//  var font: NimsFont
//  var instance: Instance
//
//  var body: some View {
//    VStack(alignment: .center, spacing: 0) {
//      ForEach(instance.state.cmdlines.values, id: \.id) { cmdline in
//        HStack {
//          Spacer()
//
//          VStack(alignment: .leading, spacing: 4) {
//            if !cmdline.prompt.isEmpty {
//              let attributedString = AttributedString(
//                cmdline.prompt,
//                attributes: .init([
//                  .font: font.nsFont(isItalic: true),
//                  .foregroundColor: instance.state.appearance.defaultForegroundColor.appKit
//                    .withAlphaComponent(0.6),
//                ])
//              )
//              Text(attributedString)
//            }
//
//            HStack(alignment: .firstTextBaseline, spacing: 10) {
//              if !cmdline.firstCharacter.isEmpty {
//                let attributedString = AttributedString(
//                  cmdline.firstCharacter,
//                  attributes: .init([
//                    .font: font.nsFont(isBold: true),
//                    .foregroundColor: instance.state.appearance.defaultForegroundColor.appKit,
//                  ])
//                )
//                Text(attributedString)
//                  .frame(width: 20, height: 20)
//                  .background(
//                    instance.state.appearance.defaultForegroundColor.swiftUI
//                      .opacity(0.2)
//                  )
//              }
//
//              ZStack(alignment: .leading) {
//                let attributedString = makeContentAttributedString(cmdline: cmdline)
//                Text(attributedString)
//
//                let isCursorAtEnd = cmdline.cursorPosition == attributedString.characters.count
//                let isBlockCursorShape = isCursorAtEnd || !cmdline.specialCharacter.isEmpty
//
//                let integerFrame = IntegerRectangle(
//                  origin: .init(column: cmdline.cursorPosition, row: 0),
//                  size: .init(columnsCount: 1, rowsCount: 1)
//                )
//                let frame = integerFrame * font.cellSize
//
//                Rectangle()
//                  .fill(instance.state.appearance.defaultForegroundColor.swiftUI)
//                  .frame(width: isBlockCursorShape ? frame.width : frame.width * 0.25, height: frame.height)
//                  .offset(x: frame.minX, y: frame.minY)
//
//                if !cmdline.specialCharacter.isEmpty {
//                  let attributedString = AttributedString(
//                    cmdline.specialCharacter,
//                    attributes: .init([
//                      .font: font.nsFont(),
//                      .foregroundColor: instance.state.appearance.defaultForegroundColor.appKit,
//                    ])
//                  )
//                  Text(attributedString)
//                    .offset(x: frame.minX, y: frame.minY)
//                }
//              }
//
//              Spacer()
//            }
//          }
//          .padding(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
//          .frame(idealWidth: 640, minHeight: 44)
//          .background {
//            let rectangle = Rectangle()
//
//            rectangle
//              .fill(
//                instance.state.appearance.defaultBackgroundColor.swiftUI.opacity(0.9)
//              )
//
//            rectangle
//              .stroke(
//                instance.state.appearance.defaultForegroundColor.swiftUI.opacity(0.1),
//                lineWidth: 1
//              )
//          }
//
//          Spacer()
//        }
//      }
//    }
//  }
//
//  @MainActor
//  private func makeContentAttributedString(cmdline: Cmdline) -> AttributedString {
//    var accumulator = AttributedString()
//
//    if !cmdline.blockLines.isEmpty {
//      for blockLine in cmdline.blockLines {
//        var lineAccumulator = AttributedString()
//
//        for contentPart in blockLine {
//          let attributedString = AttributedString(
//            contentPart.text,
//            attributes: .init([
//              .font: font.nsFont(),
//              .foregroundColor: instance.state.appearance.foregroundColor(for: contentPart.highlightID).swiftUI,
//              .backgroundColor: instance.state.appearance.backgroundColor(for: contentPart.highlightID).swiftUI,
//            ])
//          )
//          lineAccumulator.append(attributedString)
//        }
//
//        accumulator.append(lineAccumulator)
//        accumulator.append(AttributedString("\n"))
//      }
//    }
//
//    var attributedString = cmdline.contentParts
//      .map { contentPart -> AttributedString in
//        AttributedString(
//          contentPart.text,
//          attributes: .init([
//            .font: font.nsFont(),
//            .foregroundColor: instance.state.appearance.foregroundColor(for: contentPart.highlightID).swiftUI,
//            .backgroundColor: instance.state.appearance.backgroundColor(for: contentPart.highlightID).swiftUI,
//          ])
//        )
//      }
//      .reduce(AttributedString()) { result, next in
//        var copy = result
//        copy.append(next)
//        return copy
//      }
//
//    if !cmdline.specialCharacter.isEmpty, cmdline.shiftAfterSpecialCharacter {
//      let insertPosition = attributedString.index(
//        attributedString.startIndex,
//        offsetByCharacters: cmdline.cursorPosition
//      )
//
//      attributedString.insert(
//        AttributedString(
//          "".padding(toLength: cmdline.specialCharacter.count, withPad: " ", startingAt: 0),
//          attributes: .init([.font: font])
//        ),
//        at: insertPosition
//      )
//    }
//
//    accumulator.append(attributedString)
//
//    return accumulator
//  }
// }
//
