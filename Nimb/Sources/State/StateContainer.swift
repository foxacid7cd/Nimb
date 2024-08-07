// SPDX-License-Identifier: MIT

@MainActor
public protocol StateContainer: AnyObject {
  var state: State { get set }
}
