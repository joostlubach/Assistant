import UIKit

public protocol TooltipProvider: class {

  /// Gets the view onto which the tooltips are added.
  var tooltipContainerView: UIView { get }

  /// Provides tooltips for this provider.
  func provideTooltips(tooltips: TooltipProvisioner)

}

public class TooltipProvisioner {

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
  public func assign(tooltip: Tooltip, toButton targetButton: UIButton, spacing: CGFloat? = nil) -> TooltipAssignment {
    let assignment = TooltipAssignment(tooltip: tooltip, provider: provider, target: TooltipTarget.Button(targetButton), spacing: spacing)
    assignments.append(assignment)
    return assignment
  }

  /// Assigns a tooltip to an arbitrary view. The tooltip has to be manually invalidated.
  ///
  /// - parameter tooltip:     The tooltip to assign.
  /// - parameter targetView:  The target view to assign the tooltip to.
  /// - parameter spacing:     A non-default spacing between the tooltip and the target view.
  /// - returns:           The assignment for this
  public func assign(tooltip: Tooltip, toView targetView: UIView, spacing: CGFloat? = nil) -> TooltipAssignment {
    let assignment = TooltipAssignment(tooltip: tooltip, provider: provider, target: TooltipTarget.View(targetView), spacing: spacing)
    assignments.append(assignment)
    return assignment
  }

  /// Assigns a tooltip to an arbitrary rect. The tooltip has to be manually invalidated.
  ///
  /// - parameter tooltip:     The tooltip to assign.
  /// - parameter targetRect:  The target rect to assign the tooltip to.
  /// - parameter spacing:     A non-default spacing between the tooltip and the target view.
  /// - returns:           The assignment for this
  public func assign(tooltip: Tooltip, toRect targetRect: CGRect, spacing: CGFloat? = nil) -> TooltipAssignment {
    let assignment = TooltipAssignment(tooltip: tooltip, provider: provider, target: TooltipTarget.Rect(targetRect), spacing: spacing)
    assignments.append(assignment)
    return assignment
  }

  /// Assigns a tooltip to an arbitrary point. The tooltip has to be manually invalidated.
  ///
  /// - parameter tooltip:      The tooltip to assign.
  /// - parameter targetPoint:  The target point to assign the tooltip to.
  /// - parameter spacing:      A non-default spacing between the tooltip and the target view.
  /// - returns:            The assignment for this
  public func assign(tooltip: Tooltip, toPoint targetPoint: CGPoint, spacing: CGFloat? = nil) -> TooltipAssignment {
    let rect = CGRect(origin: targetPoint, size: CGSizeMake(1, 1))
    let assignment = TooltipAssignment(tooltip: tooltip, provider: provider, target: TooltipTarget.Rect(rect), spacing: spacing)
    assignments.append(assignment)
    return assignment
  }

  /// Assigns a tooltip to an dynamically changing rect. The tooltip has to be manually invalidated.
  ///
  /// - parameter tooltip:  The tooltip to assign.
  /// - parameter spacing:  A non-default spacing between the tooltip and the target view.
  /// - parameter block:    This block is invoked whenever the tooltip is laid out.
  /// - returns:            The assignment for this
  public func assignToDynamicRect(tooltip: Tooltip, spacing: CGFloat? = nil, block: () -> CGRect) -> TooltipAssignment {
    let assignment = TooltipAssignment(tooltip: tooltip, provider: provider, target: TooltipTarget.DynamicRect(block), spacing: spacing)
    assignments.append(assignment)
    return assignment
  }

  /// Assigns a tooltip to an dynamically changing point. The tooltip has to be manually invalidated.
  ///
  /// - parameter tooltip:  The tooltip to assign.
  /// - parameter spacing:  A non-default spacing between the tooltip and the target view.
  /// - parameter block:    This block is invoked whenever the tooltip is laid out.
  /// - returns:            The assignment for this
  public func assignToDynamicPoint(tooltip: Tooltip, spacing: CGFloat? = nil, block: () -> CGPoint) -> TooltipAssignment {
    let rectBlock = { CGRect(origin: block(), size: CGSizeMake(1, 1)) }
    let assignment = TooltipAssignment(tooltip: tooltip, provider: provider, target: TooltipTarget.DynamicRect(rectBlock), spacing: spacing)
    assignments.append(assignment)
    return assignment
  }

  /// Retracts a previously assigned tooltip. All added assignments for this tooltip are removed.
  public func retract(tooltip: Tooltip) {
    assignments = assignments.filter { $0.tooltip != tooltip }
  }

}