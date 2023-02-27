// SPDX-License-Identifier: MIT

import ComposableArchitecture
import Library
import Neovim
import SwiftUI

public struct HeaderView: View {
  public init(store: Store<Model, Action>) {
    self.store = store
  }

  public var store: Store<Model, Action>

  public struct Model {
    public init(tabline: Tabline? = nil, gridsLayoutUpdateFlag: Bool) {
      self.tabline = tabline
      self.gridsLayoutUpdateFlag = gridsLayoutUpdateFlag
    }

    public var tabline: Tabline?
    public var gridsLayoutUpdateFlag: Bool
  }

  public enum Action: Sendable {
    case reportSelectedTab(id: Tab.ID)
    case sideMenuButtonPressed
  }

  @Environment(\.nimsAppearance)
  private var nimsAppearance: NimsAppearance

  public var body: some View {
    let foregroundColor = nimsAppearance.defaultForegroundColor.swiftUI

    WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: { $0.gridsLayoutUpdateFlag == $1.gridsLayoutUpdateFlag },
      content: { viewStore in
        let model = viewStore.state

        HStack(alignment: .center) {
          Button {
            viewStore.send(.sideMenuButtonPressed)

          } label: {
            Image(systemName: "sidebar.left", variableValue: 1)
          }
          .tint(foregroundColor)
          .buttonStyle(.borderless)
          .frame(maxHeight: .infinity)
          .fixedSize(horizontal: true, vertical: false)

          ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
              let tabs = model.tabline?.tabs ?? []

              ForEach(tabs) { tab in
                Button {
                  viewStore.send(.reportSelectedTab(id: tab.id))

                } label: {
                  Text(tab.name)
                    .font(.system(size: 11))
                }
                .buttonStyle(
                  TabButtonStyle(
                    foregroundColor: foregroundColor,
                    isSelected: tab.id == model.tabline?.currentTabID
                  )
                )
              }
            }
          }
        }
        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
      }
    )

    .background(nimsAppearance.defaultBackgroundColor.swiftUI)
  }

  public struct TabButtonStyle: SwiftUI.ButtonStyle {
    public var foregroundColor: SwiftUI.Color
    public var isSelected: Bool

    public func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
        .foregroundColor(foregroundColor)
        .opacity(isSelected ? 1 : 0.5)
    }
  }
}
