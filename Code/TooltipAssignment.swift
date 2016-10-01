import UIKit

/// An assignment of a tooltip to some target.
open class TooltipAssignment {

  /// Initializes a new tooltip assignment.
  init(tooltip: Tooltip, provider: TooltipProvider, target: TooltipTarget, spacing: CGFloat? = nil) {
    self.tooltip = tooltip
    self.provider = provider
    self.target = target
    self.spacing = spacing

    setupAutoInvalidation()
  }

  deinit {
    tearDownAutoInvalidation()
  }

  /// The tooltip itself.
  open let tooltip: Tooltip

  /// The provider providing this assignment.
  open let provider: TooltipProvider

  /// The target of the tooltip.
  open let target: TooltipTarget

  /// The spacing between the tooltip and the target. If `nil`, a default spacing is used.
  open var spacing: CGFloat?

  // MARK: - Auto-invalidation

  private lazy var invalidationTarget: InvalidationTarget = InvalidationTarget(tooltip: self.tooltip)

  private func setupAutoInvalidation() {
    if let button = target.targetButton {
      button.addTarget(invalidationTarget, action: #selector(InvalidationTarget.invalidate), for: .touchUpInside)
    }
  }

  private func tearDownAutoInvalidation() {
    if let button = target.targetButton {
      button.removeTarget(invalidationTarget, action: #selector(InvalidationTarget.invalidate), for: .touchUpInside)
    }
  }
  
}

extension TooltipAssignment: Hashable, Equatable {

  public var hashValue: Int {
    var hashValue = tooltip.hashValue
    if let providerObject = provider as? NSObject {
      hashValue |= providerObject.hashValue
    }
    if let view = target.targetView {
      hashValue |= view.hashValue
    }
    return hashValue
  }

}

public func ==(lhs: TooltipAssignment, rhs: TooltipAssignment) -> Bool {
  if lhs.tooltip != rhs.tooltip {
    return false
  }
  if lhs.provider !== rhs.provider {
    return false
  }
  if lhs.target.targetView !== rhs.target.targetView {
    return false
  }

  return true
}

/// Class used in automatically invalidating an object.
class InvalidationTarget: NSObject {

  init(tooltip: Tooltip) {
    self.tooltip = tooltip
  }

  let tooltip: Tooltip

  func invalidate() {
    tooltip.markAsSeen()
  }

}

/// An assignment target of a tooltip.
public enum TooltipTarget {

  /// The tooltip is assigned to a button. When the button is tapped, the tooltip is invalidated.
  case button(UIButton)

  /// The tooltip is attached to some arbitrary view. The tooltip has to be manually invalidated.
  case view(UIView)

  /// The tooltip is attached to some arbitrary rect. The tooltip has to be manually invalidated.
  case rect(CGRect)

  /// The tooltip is attached to some rect that might change. The block is invoked at every layout pass.
  case dynamicRect(() -> CGRect)

  /// The target button, if any.
  var targetButton: UIButton? {
    switch self {
    case let .button(button): return button
    default: return nil
    }
  }

  /// The target view, if any.
  var targetView: UIView? {
    switch self {
    case let .button(button): return button
    case let .view(view): return view
    default: return nil
    }
  }

  /// The target rect, converted to the coordinate space of the given view, if possible.
  func targetRectInView(_ referenceView: UIView) -> CGRect {
    switch self {
    case let .button(button):
      return button.convert(button.bounds, to: referenceView)
    case let .view(view):
      return view.convert(view.bounds, to: referenceView)
    case let .rect(rect):
      // Not possible to convert, just use the rect.
      return rect
    case let .dynamicRect(block):
      return block()
    }
  }
  
}
