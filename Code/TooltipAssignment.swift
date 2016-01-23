import UIKit

/// An assignment of a tooltip to some target.
public class TooltipAssignment {

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
  public let tooltip: Tooltip

  /// The provider providing this assignment.
  public let provider: TooltipProvider

  /// The target of the tooltip.
  public let target: TooltipTarget

  /// The spacing between the tooltip and the target. If `nil`, a default spacing is used.
  public var spacing: CGFloat?

  // MARK: - Auto-invalidation

  private lazy var invalidationTarget: InvalidationTarget = InvalidationTarget(tooltip: self.tooltip)

  private func setupAutoInvalidation() {
    if let button = target.targetButton {
      button.addTarget(invalidationTarget, action: "invalidate", forControlEvents: .TouchUpInside)
    }
  }

  private func tearDownAutoInvalidation() {
    if let button = target.targetButton {
      button.removeTarget(invalidationTarget, action: "invalidate", forControlEvents: .TouchUpInside)
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
  case Button(UIButton)

  /// The tooltip is attached to some arbitrary view. The tooltip has to be manually invalidated.
  case View(UIView)

  /// The tooltip is attached to some arbitrary rect. The tooltip has to be manually invalidated.
  case Rect(CGRect)

  /// The tooltip is attached to some rect that might change. The block is invoked at every layout pass.
  case DynamicRect(() -> CGRect)

  /// The target button, if any.
  var targetButton: UIButton? {
    switch self {
    case let .Button(button): return button
    default: return nil
    }
  }

  /// The target view, if any.
  var targetView: UIView? {
    switch self {
    case let .Button(button): return button
    case let .View(view): return view
    default: return nil
    }
  }

  /// The target rect, converted to the coordinate space of the given view, if possible.
  func targetRectInView(referenceView: UIView) -> CGRect {
    switch self {
    case let .Button(button):
      return button.convertRect(button.bounds, toView: referenceView)
    case let .View(view):
      return view.convertRect(view.bounds, toView: referenceView)
    case let .Rect(rect):
      // Not possible to convert, just use the rect.
      return rect
    case let .DynamicRect(block):
      return block()
    }
  }
  
}