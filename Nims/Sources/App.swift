// SPDX-License-Identifier: MIT

import ComposableArchitecture
import InstanceFeature
import NimsFeature
import SwiftUI

@main @MainActor
struct App: SwiftUI.App {
  var body: some Scene {
    Nims.Scene(store)
  }

  private var store = StoreOf<Nims>(
    initialState: .init(),
    reducer: Nims()
  )
}
