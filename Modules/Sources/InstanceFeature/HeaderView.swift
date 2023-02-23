// SPDX-License-Identifier: MIT

import ComposableArchitecture
import Library
import Neovim
import SwiftUI

public struct HeaderView: View {
  public init(store: Store<Model, Action>) {
    self.store = store
    viewStore = ViewStore(
      store,
      observe: { $0 },
      removeDuplicates: { $0.gridsLayoutUpdateFlag == $1.gridsLayoutUpdateFlag }
    )
  }

  public var store: Store<Model, Action>

  public struct Model: Equatable {
    public var tabline: Tabline?
    public var gridsLayoutUpdateFlag: Bool
  }

  public enum Action: Equatable {
    case reportSelectedTab(id: Tab.ID)
  }

  @Environment(\.nimsAppearance)
  private var nimsAppearance: NimsAppearance

  @ObservedObject
  private var viewStore: ViewStore<Model, Action>

  public var body: some View {
    let foregroundColor = nimsAppearance.defaultForegroundColor.swiftUI

    HStack(alignment: .center) {
      Button {
        print()

      } label: {
        Image(systemName: "sidebar.left", variableValue: nil)
      }
      .tint(foregroundColor)
      .buttonStyle(.borderless)
      .frame(width: 24, height: 24)

      if let tabline = viewStore.tabline {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(alignment: .center, spacing: 2) {
            ForEach(tabline.tabs) { tab in
              let isSelected = tab.id == tabline.currentTabID

              Button {
                viewStore.send(.reportSelectedTab(id: tab.id))

              } label: {
                Text(tab.name)
                  .font(.system(size: 11))
              }
              .buttonStyle(
                TabButtonStyle(
                  foregroundColor: foregroundColor,
                  isSelected: isSelected
                )
              )
            }
          }
        }
      }
    }
    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
  }

  public struct TabButtonStyle: SwiftUI.ButtonStyle {
    public var foregroundColor: SwiftUI.Color
    public var isSelected: Bool

    public func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .padding(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
        .foregroundColor(foregroundColor)
        .opacity(isSelected ? 1 : 0.5)
    }
  }
}
