import UIKit

public protocol TooltipProvider: class {

  /// Gets the view onto which the tooltips are added.
  var tooltipContainerView: UIView { get }

  /// Provides tooltips for this provider.
  func provideTooltips(_ tooltips: TooltipProvisioner)

}

open class TooltipProvisioner {

  init(provider: TooltipProvider) {
    self.provider = provider
  }

  /// The provider providing the tooltips.
  let provider: TooltipProvider

  /// The list of tooltip assignments.
  var assignments = [TooltipAssignment]()

  /// Assigns a tooltip to a button. When the button is tapped, the tooltip is invalidated.
  ///
  /// - parameter tooltip:       The tooltip to assign.
  /// - parameter targetButton:  The target button to assign the tooltip to.
  /// - parameter spacing:       A non-default spacing between the tooltip and the target view.
  /// - returns:             The assignment for this
  @discardableResult
  open func assign(_ tooltip: Tooltip, toButton targetButton: UIButton, spacing: CGFloat? = nil) -> TooltipAssignment {
    let assignment = TooltipAssignment(tooltip: tooltip, provider: provider, target: TooltipTarget.button(targetButton), spacing: spacing)
    assignments.append(assignment)
    return assignment
  }

  /// Assigns a tooltip to an arbitrary view. The tooltip has to be manually invalidated.
  ///
  /// - parameter tooltip:     The tooltip to assign.
  /// - parameter targetView:  The target view to assign the tooltip to.
  /// - parameter spacing:     A non-default spacing between the tooltip and the target view.
  /// - returns:           The assignment for this
  @discardableResult
  open func assign(_ tooltip: Tooltip, toView targetView: UIView, spacing: CGFloat? = nil) -> TooltipAssignment {
    let assignment = TooltipAssignment(tooltip: tooltip, provider: provider, target: TooltipTarget.view(targetView), spacing: spacing)
    assignments.append(assignment)
    return assignment
  }

  /// Assigns a tooltip to an arbitrary rect. The tooltip has to be manually invalidated.
  ///
  /// - parameter tooltip:     The tooltip to assign.
  /// - parameter targetRect:  The target rect to assign the tooltip to.
  /// - parameter spacing:     A non-default spacing between the tooltip and the target view.
  /// - returns:           The assignment for this
  @discardableResult
  open func assign(_ tooltip: Tooltip, toRect targetRect: CGRect, spacing: CGFloat? = nil) -> TooltipAssignment {
    let assignment = TooltipAssignment(tooltip: tooltip, provider: provider, target: TooltipTarget.rect(targetRect), spacing: spacing)
    assignments.append(assignment)
    return assignment
  }

  /// Assigns a tooltip to an arbitrary point. The tooltip has to be manually invalidated.
  ///
  /// - parameter tooltip:      The tooltip to assign.
  /// - parameter targetPoint:  The target point to assign the tooltip to.
  /// - parameter spacing:      A non-default spacing between the tooltip and the target view.
  /// - returns:            The assignment for this
  @discardableResult
  open func assign(_ tooltip: Tooltip, toPoint targetPoint: CGPoint, spacing: CGFloat? = nil) -> TooltipAssignment {
    let rect = CGRect(origin: targetPoint, size: CGSize(width: 1, height: 1))
    let assignment = TooltipAssignment(tooltip: tooltip, provider: provider, target: TooltipTarget.rect(rect), spacing: spacing)
    assignments.append(assignment)
    return assignment
  }

  /// Assigns a tooltip to an dynamically changing rect. The tooltip has to be manually invalidated.
  ///
  /// - parameter tooltip:  The tooltip to assign.
  /// - parameter spacing:  A non-default spacing between the tooltip and the target view.
  /// - parameter block:    This block is invoked whenever the tooltip is laid out.
  /// - returns:            The assignment for this
  @discardableResult
  open func assignToDynamicRect(_ tooltip: Tooltip, spacing: CGFloat? = nil, block: @escaping () -> CGRect) -> TooltipAssignment {
    let assignment = TooltipAssignment(tooltip: tooltip, provider: provider, target: TooltipTarget.dynamicRect(block), spacing: spacing)
    assignments.append(assignment)
    return assignment
  }

  /// Assigns a tooltip to an dynamically changing point. The tooltip has to be manually invalidated.
  ///
  /// - parameter tooltip:  The tooltip to assign.
  /// - parameter spacing:  A non-default spacing between the tooltip and the target view.
  /// - parameter block:    This block is invoked whenever the tooltip is laid out.
  /// - returns:            The assignment for this
  @discardableResult
  open func assignToDynamicPoint(_ tooltip: Tooltip, spacing: CGFloat? = nil, block: @escaping () -> CGPoint) -> TooltipAssignment {
    let rectBlock = { CGRect(origin: block(), size: CGSize(width: 1, height: 1)) }
    let assignment = TooltipAssignment(tooltip: tooltip, provider: provider, target: TooltipTarget.dynamicRect(rectBlock), spacing: spacing)
    assignments.append(assignment)
    return assignment
  }

  /// Retracts a previously assigned tooltip. All added assignments for this tooltip are removed.
  open func retract(_ tooltip: Tooltip) {
    assignments = assignments.filter { $0.tooltip != tooltip }
  }

}
