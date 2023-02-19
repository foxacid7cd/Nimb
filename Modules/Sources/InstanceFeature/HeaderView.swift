// SPDX-License-Identifier: MIT

import Neovim
import SwiftUI

public struct HeaderView: View {
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

  public var instanceViewModel: InstanceViewModel
  public var tabline: Tabline?
  public var action: (Tab.ID) -> Void

  public var body: some View {
    let foregroundColor = instanceViewModel.defaultForegroundColor.swiftUI

    HStack(alignment: .center) {
      Button {
        print()

      } label: {
        Image(systemName: "sidebar.left", variableValue: nil)
      }
      .tint(foregroundColor)
      .buttonStyle(.borderless)
      .frame(width: 24, height: 24)

      Spacer()

      if let tabline {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(alignment: .center, spacing: 2) {
            ForEach(tabline.tabs) { tab in
              let isSelected = tab.id == tabline.currentTabID

              Button {
                action(tab.id)

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
}
