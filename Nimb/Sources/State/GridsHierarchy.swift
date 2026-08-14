// SPDX-License-Identifier: MIT

import Collections
import NimbCore

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
    allNodes[node.parent]?.children.remove(id)
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
    guard var parentNode = allNodes[node.parent] else {
      return false
    }
    var orderChanged = false
    let lastElementIndex = parentNode.children.index(before: parentNode.children.endIndex)
    if
      let index = parentNode.children.firstIndex(of: id),
      index != lastElementIndex
    {
      parentNode.children.remove(at: index)
      parentNode.children.append(id)
      allNodes[node.parent] = parentNode
      orderChanged = true
    }
    return orderChanged
  }
}
