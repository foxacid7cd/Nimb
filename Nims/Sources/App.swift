// SPDX-License-Identifier: MIT

import ComposableArchitecture
import InstanceFeature
import NimsFeature
import SwiftUI

@main
struct App: SwiftUI.App {
  private let store = StoreOf<Nims>(
    initialState: .init(
      reportMouseEvent: { _ in
      }
    ),
    reducer: Nims()
  )

  var body: some Scene {
    NimsScene(store: store)
  }
}
