import UIKit

/// View displaying a tooltip.
public class TooltipView: UIView {

  public required init(tooltip: Tooltip) {
    self.tooltip = tooltip
    super.init(frame: CGRectZero)

    setup()
  }
  public required init?(coder: NSCoder) {
    fatalError("TooltipView does not support NSCoding")
  }

  /// The tooltip to display.
  public let tooltip: Tooltip

  /// The target of the tooltip.
  public internal(set) var target: TooltipTarget!

  /// The spacing of this assignment.
  public var spacing: CGFloat = 0

  /// Whether or not to enable hovering for this view.
  public var hoverEnabled = false

  /// Whether or not to enable show/hide animations for this view.
  public var showHideAnimationEnabled = false

  public lazy var tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tap")

  // MARK: Setup

  public func setup() {
    addGestureRecognizer(tapRecognizer)
    hidden = true
  }

  func tap() {
    tooltip.markAsSeen()
  }

  // MARK: - Alignment

  /// Aligns the tooltip with the target.
  func align() {
    precondition(superview != nil)
    precondition(target != nil, "You cannot add TooltipViews yourself. Use a TooltipProvider instead.")

    bounds.size.width = UIScreen.mainScreen().bounds.width
    sizeToFit()

    let anchorPoint = tooltip.anchorPointForSize(bounds.size)
    let targetRect = target.targetRectInView(superview!)
    let alignmentPoint = tooltip.alignmentPointForTargetRect(targetRect, spacing: spacing)

    center.x = alignmentPoint.x - anchorPoint.x + bounds.width / 2
    center.y = alignmentPoint.y - anchorPoint.y + bounds.height / 2

    if hidden {
      show()
    }
  }

  // MARK: Show / remove

  /// Shows this tooltip view.
  func show() {
    if showHideAnimationEnabled {
      alpha = 0
      transform = CGAffineTransformMakeScale(0.8, 0.8)
      hidden = false

      let options = UIViewAnimationOptions(rawValue: UInt(UIViewAnimationCurve.EaseInOut.rawValue))
      UIView.animateWithDuration(0.1, delay: 0.0, options: options, animations: {
        self.alpha = 1.0
        self.transform = CGAffineTransformIdentity
      }, completion: { done in
        if done {
          self.resumeAnimations()
        }
      })
    } else {
      hidden = false
      resumeAnimations()
    }
  }

  /// Hides this tooltip view, and subsequently removes it.
  public func remove() {
    if showHideAnimationEnabled {
      let options = UIViewAnimationOptions(rawValue: UInt(UIViewAnimationCurve.EaseInOut.rawValue))
      UIView.animateWithDuration(0.1, delay: 0.0, options: options, animations: {
        self.alpha = 0
        self.transform = CGAffineTransformMakeScale(0.8, 0.8)
        }, completion: { _ in
          self.hidden = true
          self.removeFromSuperview()
      })
    } else {
      hidden = true
      removeFromSuperview()
    }
  }

  // MARK: Animations

  public func suspendAnimations() {
    if layer.animationForKey("hover") != nil {
      stopHover()
    }
  }

  public func resumeAnimations() {
    if hoverEnabled && layer.animationForKey("hover") == nil {
      startHover()
    }
  }

  private func startHover() {
    CATransaction.flush()

    let animation = CABasicAnimation(keyPath: "transform.translation")

    animation.duration = 1
    animation.repeatCount = Float.infinity
    animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    animation.autoreverses = true
    animation.fromValue = NSValue(CGSize: CGSizeZero)
    animation.toValue = NSValue(CGSize: tooltip.hoverOffset)

    // Start the animation at random between 0 and 1.000.000 µs.
    let randomDelay = Double(rand() % 1000) / 1000
    animation.beginTime = CACurrentMediaTime() + randomDelay

    layer.addAnimation(animation, forKey: "hover")
  }

  private func stopHover() {
    layer.removeAnimationForKey("hover")
  }

}

extension Tooltip {

  /// The offset of the hover animation for a tooltip using this alignment.
  var hoverOffset: CGSize {
    switch alignment {
    case .None: return CGSizeZero
    case .Top: return CGSizeMake(0, 2)
    case .Bottom: return CGSizeMake(0, -2)
    case .Left: return CGSizeMake(2, 0)
    case .Right: return CGSizeMake(-2, 0)
    }
  }

  /// Gets the alignment point (where the anchor of the tooltip should be placed) for the given target rectangle.
  ///
  /// - parameter rect:    The target rect.
  /// - parameter spacing: The space between the target view and the tooltip.
  /// - returns:       The alignment point.
  func alignmentPointForTargetRect(rect: CGRect, spacing: CGFloat) -> CGPoint {
    switch alignment {
    case .None:
      return CGPointMake(rect.midX, rect.midY)
    case .Top:
      return CGPointMake(rect.midX, rect.minY - spacing)
    case .Bottom:
      return CGPointMake(rect.midX, rect.maxY + spacing)
    case .Left:
      return CGPointMake(rect.minX - spacing, rect.midY)
    case .Right:
      return CGPointMake(rect.maxX + spacing, rect.midY)
    }
  }

}