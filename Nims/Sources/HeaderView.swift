// SPDX-License-Identifier: MIT

import ComposableArchitecture
import Library
import Neovim
import SwiftUI

public struct HeaderView: View {
  public init(store: StoreOf<RunningInstanceReducer>, instance: Instance) {
    self.store = store
    self.instance = instance
  }

  private var store: StoreOf<RunningInstanceReducer>
  private var instance: Instance

  @Environment(\.nimsFont)
  private var font: NimsFont

  @Environment(\.appearance)
  private var appearance: Appearance

  public var body: some View {
    let foregroundColor = appearance.defaultForegroundColor.swiftUI

    HStack(alignment: .center) {
      Button {
//          instance.state.send(.sideMenuButtonPressed)

      } label: {
        Image(systemName: "sidebar.left", variableValue: 1)
      }
      .tint(foregroundColor)
      .buttonStyle(.borderless)
      .padding(.init(top: 0, leading: 4, bottom: 0, trailing: 4))
      .frame(maxHeight: .infinity)
      .fixedSize(horizontal: true, vertical: false)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
          let tabpages = instance.state.tabline?.tabpages ?? []

          ForEach(tabpages) { tabpage in
            Button {
//                state.send(.reportSelectedTabpage(id: tabpage.id))

            } label: {
              Text(tabpage.name)
                .font(.system(size: 11))
            }
            .buttonStyle(
              TabButtonStyle(
                foregroundColor: foregroundColor,
                isSelected: tabpage.id == instance.state.tabline?.currentTabpageID
              )
            )
          }
        }
      }
    }
    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
    .background(appearance.defaultBackgroundColor.swiftUI)
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
