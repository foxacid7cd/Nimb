// SPDX-License-Identifier: MIT

public protocol StateContainer: AnyObject {
  var state: State { get set }
}
