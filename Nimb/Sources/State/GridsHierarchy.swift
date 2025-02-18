// SPDX-License-Identifier: MIT

import Collections
import CustomDump
import Overture

@PublicInit
public struct GridsHierarchy: Sendable {
  @PublicInit
  public struct Node: Sendable {
    public var id: Grid.ID
    public var parent: Grid.ID
    public var children: OrderedSet<Grid.ID>
  }

  public var allNodes: IntKeyedDictionary<Node> = .init()

  public mutating func removeNode(id: Grid.ID) {
    guard let node = allNodes.removeValue(forKey: id) else {
      return
    }
    update(&allNodes[node.parent]) { parentNode in
      guard parentNode != nil else {
        return
      }
      parentNode!.children.remove(id)
    }
  }

  public mutating func addNode(id: Grid.ID, parent: Grid.ID) {
    if var existing = allNodes[id] {
      if id != Grid.OuterID {
        allNodes[existing.parent]?.children.remove(id)
        existing.parent = parent
        allNodes[id] = existing
      }
    } else {
      allNodes[id] = .init(id: id, parent: parent, children: .init())
    }

    if id != Grid.OuterID {
      allNodes[parent]?.children.remove(id)
      allNodes[parent]?.children.append(id)
    }
  }

  public mutating func bringToFront(id: Grid.ID) -> Bool {
    guard id != Grid.OuterID, let node = allNodes[id] else {
      return false
    }
    var orderChanged = false
    update(&allNodes[node.parent]) { parentNode in
      guard parentNode != nil else {
        return
      }
      update(&parentNode!.children) { children in
        let lastElementIndex = children.index(before: children.last!)
        if let index = children.firstIndex(of: id), index != lastElementIndex {
          children.remove(at: index)
          children.append(id)
          orderChanged = true
        }
      }
    }
    return orderChanged
  }
}
