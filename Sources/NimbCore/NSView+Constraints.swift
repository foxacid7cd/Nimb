// SPDX-License-Identifier: MIT

import AppKit

/// In-repo replacement for the subset of TinyConstraints this project used.
///
/// Signatures and semantics deliberately match TinyConstraints 4.0.2 so that
/// dropping the dependency required no call-site changes:
///
///   - every method sets `translatesAutoresizingMaskIntoConstraints = false`
///     on the receiver;
///   - every method activates the constraint and returns it, so callers can
///     store it and toggle `isActive` later;
///   - `offset` is applied verbatim — callers pass their own negative values —
///     except `edgesToSuperview(insets:)`, which takes all-positive insets and
///     negates bottom/right itself.
public enum ConstraintRelation {
  case equal
  case equalOrLess
  case equalOrGreater
}

private extension NSLayoutXAxisAnchor {
  func constrain(
    _ relation: ConstraintRelation,
    to other: NSLayoutXAxisAnchor,
    constant: CGFloat,
  )
    -> NSLayoutConstraint
  {
    switch relation {
    case .equal: constraint(equalTo: other, constant: constant)
    case .equalOrLess: constraint(lessThanOrEqualTo: other, constant: constant)
    case .equalOrGreater: constraint(greaterThanOrEqualTo: other, constant: constant)
    }
  }
}

private extension NSLayoutYAxisAnchor {
  func constrain(
    _ relation: ConstraintRelation,
    to other: NSLayoutYAxisAnchor,
    constant: CGFloat,
  )
    -> NSLayoutConstraint
  {
    switch relation {
    case .equal: constraint(equalTo: other, constant: constant)
    case .equalOrLess: constraint(lessThanOrEqualTo: other, constant: constant)
    case .equalOrGreater: constraint(greaterThanOrEqualTo: other, constant: constant)
    }
  }
}

private extension NSLayoutDimension {
  func constrain(
    _ relation: ConstraintRelation,
    toConstant constant: CGFloat,
  )
    -> NSLayoutConstraint
  {
    switch relation {
    case .equal: constraint(equalToConstant: constant)
    case .equalOrLess: constraint(lessThanOrEqualToConstant: constant)
    case .equalOrGreater: constraint(greaterThanOrEqualToConstant: constant)
    }
  }

  func constrain(
    _ relation: ConstraintRelation,
    to other: NSLayoutDimension,
    multiplier: CGFloat,
    constant: CGFloat,
  )
    -> NSLayoutConstraint
  {
    switch relation {
    case .equal:
      constraint(equalTo: other, multiplier: multiplier, constant: constant)
    case .equalOrLess:
      constraint(lessThanOrEqualTo: other, multiplier: multiplier, constant: constant)
    case .equalOrGreater:
      constraint(greaterThanOrEqualTo: other, multiplier: multiplier, constant: constant)
    }
  }
}

public extension NSView {
  private func activating(
    _ constraint: NSLayoutConstraint,
    _ priority: NSLayoutConstraint.Priority,
  )
    -> NSLayoutConstraint
  {
    translatesAutoresizingMaskIntoConstraints = false
    constraint.priority = priority
    constraint.isActive = true
    return constraint
  }

  private var requiredSuperview: NSView {
    guard let superview else {
      preconditionFailure("\(self) has no superview")
    }
    return superview
  }

  // MARK: - Edges relative to another view

  @discardableResult
  func leading(
    to view: NSView,
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(
      leadingAnchor.constrain(relation, to: view.leadingAnchor, constant: offset),
      priority,
    )
  }

  @discardableResult
  func trailing(
    to view: NSView,
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(
      trailingAnchor.constrain(relation, to: view.trailingAnchor, constant: offset),
      priority,
    )
  }

  @discardableResult
  func top(
    to view: NSView,
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(
      topAnchor.constrain(relation, to: view.topAnchor, constant: offset),
      priority,
    )
  }

  @discardableResult
  func bottom(
    to view: NSView,
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(
      bottomAnchor.constrain(relation, to: view.bottomAnchor, constant: offset),
      priority,
    )
  }

  // MARK: - Edges relative to the superview

  @discardableResult
  func leadingToSuperview(
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    leading(to: requiredSuperview, offset: offset, relation: relation, priority: priority)
  }

  @discardableResult
  func trailingToSuperview(
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    trailing(to: requiredSuperview, offset: offset, relation: relation, priority: priority)
  }

  @discardableResult
  func topToSuperview(
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    top(to: requiredSuperview, offset: offset, relation: relation, priority: priority)
  }

  @discardableResult
  func bottomToSuperview(
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    bottom(to: requiredSuperview, offset: offset, relation: relation, priority: priority)
  }

  /// Note the sign convention: insets are all positive, and bottom/right are
  /// negated here. This differs from the individual edge methods above, where
  /// the caller supplies the sign. TinyConstraints behaved the same way.
  @discardableResult
  func edgesToSuperview(insets: NSEdgeInsets = .init()) -> [NSLayoutConstraint] {
    [
      topToSuperview(offset: insets.top),
      leadingToSuperview(offset: insets.left),
      bottomToSuperview(offset: -insets.bottom),
      trailingToSuperview(offset: -insets.right),
    ]
  }

  // MARK: - Edge pinned to the opposite edge of another view

  @discardableResult
  func leadingToTrailing(
    of view: NSView,
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(
      leadingAnchor.constrain(relation, to: view.trailingAnchor, constant: offset),
      priority,
    )
  }

  @discardableResult
  func trailingToLeading(
    of view: NSView,
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(
      trailingAnchor.constrain(relation, to: view.leadingAnchor, constant: offset),
      priority,
    )
  }

  @discardableResult
  func topToBottom(
    of view: NSView,
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(
      topAnchor.constrain(relation, to: view.bottomAnchor, constant: offset),
      priority,
    )
  }

  @discardableResult
  func bottomToTop(
    of view: NSView,
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(
      bottomAnchor.constrain(relation, to: view.topAnchor, constant: offset),
      priority,
    )
  }

  // MARK: - Centering

  @discardableResult
  func centerX(
    to view: NSView,
    offset: CGFloat = 0,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(
      centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset),
      priority,
    )
  }

  @discardableResult
  func centerY(
    to view: NSView,
    offset: CGFloat = 0,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(
      centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: offset),
      priority,
    )
  }

  /// Uses the `NSLayoutConstraint(item:attribute:...)` initialiser rather than
  /// an anchor, because anchors cannot express a multiplier on a center
  /// attribute. `centerYToSuperview(multiplier: 0.65)` in MainViewController
  /// depends on this.
  @discardableResult
  func centerXToSuperview(
    offset: CGFloat = 0,
    multiplier: CGFloat = 1,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(
      NSLayoutConstraint(
        item: self,
        attribute: .centerX,
        relatedBy: .equal,
        toItem: requiredSuperview,
        attribute: .centerX,
        multiplier: multiplier,
        constant: offset,
      ),
      priority,
    )
  }

  @discardableResult
  func centerYToSuperview(
    offset: CGFloat = 0,
    multiplier: CGFloat = 1,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(
      NSLayoutConstraint(
        item: self,
        attribute: .centerY,
        relatedBy: .equal,
        toItem: requiredSuperview,
        attribute: .centerY,
        multiplier: multiplier,
        constant: offset,
      ),
      priority,
    )
  }

  @discardableResult
  func centerInSuperview() -> [NSLayoutConstraint] {
    [centerXToSuperview(), centerYToSuperview()]
  }

  // MARK: - Dimensions

  @discardableResult
  func width(
    _ width: CGFloat,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(widthAnchor.constrain(relation, toConstant: width), priority)
  }

  @discardableResult
  func height(
    _ height: CGFloat,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(heightAnchor.constrain(relation, toConstant: height), priority)
  }

  @discardableResult
  func width(
    min: CGFloat,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    width(min, relation: .equalOrGreater, priority: priority)
  }

  @discardableResult
  func width(
    max: CGFloat,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    width(max, relation: .equalOrLess, priority: priority)
  }

  @discardableResult
  func height(
    min: CGFloat,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    height(min, relation: .equalOrGreater, priority: priority)
  }

  @discardableResult
  func height(
    max: CGFloat,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    height(max, relation: .equalOrLess, priority: priority)
  }

  @discardableResult
  func width(
    to view: NSView,
    _ dimension: NSLayoutDimension? = nil,
    multiplier: CGFloat = 1,
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(
      widthAnchor.constrain(
        relation,
        to: dimension ?? view.widthAnchor,
        multiplier: multiplier,
        constant: offset,
      ),
      priority,
    )
  }

  @discardableResult
  func height(
    to view: NSView,
    _ dimension: NSLayoutDimension? = nil,
    multiplier: CGFloat = 1,
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    activating(
      heightAnchor.constrain(
        relation,
        to: dimension ?? view.heightAnchor,
        multiplier: multiplier,
        constant: offset,
      ),
      priority,
    )
  }

  @discardableResult
  func widthToSuperview(
    _ dimension: NSLayoutDimension? = nil,
    multiplier: CGFloat = 1,
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    width(
      to: requiredSuperview,
      dimension,
      multiplier: multiplier,
      offset: offset,
      relation: relation,
      priority: priority,
    )
  }

  @discardableResult
  func heightToSuperview(
    _ dimension: NSLayoutDimension? = nil,
    multiplier: CGFloat = 1,
    offset: CGFloat = 0,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> NSLayoutConstraint
  {
    height(
      to: requiredSuperview,
      dimension,
      multiplier: multiplier,
      offset: offset,
      relation: relation,
      priority: priority,
    )
  }

  // MARK: - Content priorities

  /// Shorthand for `setContentCompressionResistancePriority(_:for:)`, which is
  /// what TinyConstraints named `setCompressionResistance(_:for:)`.
  func setCompressionResistance(
    _ priority: NSLayoutConstraint.Priority,
    for axis: NSLayoutConstraint.Orientation,
  ) {
    setContentCompressionResistancePriority(priority, for: axis)
  }

  /// Shorthand for `setContentHuggingPriority(_:for:)`.
  func setHugging(
    _ priority: NSLayoutConstraint.Priority,
    for axis: NSLayoutConstraint.Orientation,
  ) {
    setContentHuggingPriority(priority, for: axis)
  }

  @discardableResult
  func size(
    _ size: CGSize,
    relation: ConstraintRelation = .equal,
    priority: NSLayoutConstraint.Priority = .required,
  )
    -> [NSLayoutConstraint]
  {
    [
      width(size.width, relation: relation, priority: priority),
      height(size.height, relation: relation, priority: priority),
    ]
  }
}
