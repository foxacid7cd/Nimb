//
//  State.swift
//
//
//  Created by Yevhenii Matviienko on 28.12.2022.
//

import IdentifiedCollections
import Library
import Neovim
import Tagged

public struct State: Sendable, Equatable, Identifiable {
  public var id: ID
  public var font: Font?
  public var grids: IdentifiedArrayOf<Grid>

  public init(id: ID, font: Font? = nil, grids: IdentifiedArrayOf<Grid> = .init()) {
    self.id = id
    self.font = font
    self.grids = grids
  }

  public typealias ID = Tagged<State, String>

  public struct Grid: Sendable, Equatable, Identifiable {
    public var id: ID
    public var cells: TwoDimensionalArray<Cell>

    public typealias ID = Tagged<Grid, Int>

    public init(id: ID, cells: TwoDimensionalArray<Cell>) {
      self.id = id
      self.cells = cells
    }
  }
}

extension State.Grid.ID {
  public static var outer: Self {
    1
  }

  public var isOuter: Bool {
    self == .outer
  }
}
