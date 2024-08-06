// SPDX-License-Identifier: MIT

import AppKit

protocol NibLoadable {
  static var nibName: String { get }
  static func createFromNib(in bundle: Bundle) -> Self
}

extension NibLoadable where Self: NSView {
  static var nibName: String {
    String(describing: Self.self)
  }

  static func createFromNib(in bundle: Bundle = Bundle.main) -> Self {
    var topLevelArray: NSArray? = nil
    bundle.loadNibNamed(NSNib.Name(nibName), owner: self, topLevelObjects: &topLevelArray)
    let views = [Any](topLevelArray!).filter { $0 is Self }
    return views.last as! Self
  }
}
