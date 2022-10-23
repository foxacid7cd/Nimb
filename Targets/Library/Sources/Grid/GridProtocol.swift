//
//  GridProtocol.swift
//  Library
//
//  Created by Yevhenii Matviienko on 24.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public protocol GridProtocol {
  associatedtype Element

  var size: GridSize { get }

  subscript(index: GridPoint) -> Element { get }
}
