//
//  Nims.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import API
import Drawing
import SwiftUI

@main
enum Nims {
  private static let appDelegate = AppDelegate()

  static func main() {
    let application = NSApplication.shared
    application.delegate = appDelegate
    application.run()
  }
}

/*@main
 struct Nims: App {
   @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

   @StateObject var store = Store()

   var body: some Scene {
     Window(.init(verbatim: "Nims"), id: "Main") {
       if let currentGridID = store.state.currentGridID, let currentGrid = store.state.grids[currentGridID] {
         Canvas { context, size in
           context.draw(
             context.resolve(.init(verbatim: "\(currentGrid)").font(.system(size: 24, weight: .bold, design: .monospaced))),
             in: .init(origin: .zero, size: size)
           )
         }
         .frame(
           width: store.state.cellSize.width * CGFloat(currentGrid.width),
           height: store.state.cellSize.height * CGFloat(currentGrid.height),
           alignment: .topLeading
         )

       } else {
         EmptyView()
           .hidden()
       }
     }
   }
 }*/
