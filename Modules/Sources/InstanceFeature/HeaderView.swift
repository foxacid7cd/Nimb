// SPDX-License-Identifier: MIT

import Neovim
import SwiftUI

public struct HeaderView: View {
  public struct ButtonStyle: SwiftUI.ButtonStyle {
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
  public var action: (References.Tabpage) -> Void

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
            let items = makeViewItems(for: tabline)

            ForEach(items, id: \.self) { item in
              Button {
                action(item.reference)

              } label: {
                Text(item.name)
                  .font(.system(size: 11))
              }
              .buttonStyle(ButtonStyle(foregroundColor: foregroundColor, isSelected: item.isSelected))
            }
          }
        }
      }
    }
    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
  }

  private struct TabViewItem: Hashable, Identifiable {
    public var reference: References.Tabpage
    public var name: String
    public var isSelected: Bool

    public var id: some Hashable {
      reference
    }
  }

  private func makeViewItems(for tabline: Tabline) -> [TabViewItem] {
    tabline.tabs
      .map { tab in
        .init(
          reference: tab.reference,
          name: tab.name,
          isSelected: tab.reference == tabline.currentTab
        )
      }
  }
}
