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
  public var windows: IdentifiedArrayOf<Window>

  public init(
    id: ID,
    font: Font? = nil,
    grids: IdentifiedArrayOf<Grid> = [],
    windows: IdentifiedArrayOf<Window> = []
  ) {
    self.id = id
    self.font = font
    self.grids = grids
    self.windows = windows
  }

  public var outerGrid: Grid? {
    get {
      grids[id: .outer]
    }
    set {
      grids[id: .outer] = newValue
    }
  }

  public typealias ID = Tagged<State, String>

  public struct Grid: Sendable, Equatable, Identifiable {
    public var id: ID
    public var cells: TwoDimensionalArray<Cell>

    public init(id: ID, cells: TwoDimensionalArray<Cell>) {
      self.id = id
      self.cells = cells
    }

    public typealias ID = Tagged<Grid, Int>
  }

  public struct Window: Sendable, Equatable, Identifiable {
    public var id: ID
    public var gridID: Grid.ID
    public var frame: IntegerRectangle

    public init(id: ID, gridID: Grid.ID, frame: IntegerRectangle) {
      self.id = id
      self.gridID = gridID
      self.frame = frame
    }

    public typealias ID = Tagged<Window, Int>
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
