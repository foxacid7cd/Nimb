//
//  Nims.swift
//
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//

import SwiftUI

@main
struct Nims: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      EmptyView()
        .frame(width: 300, height: 300, alignment: .center)
    }
  }
}
