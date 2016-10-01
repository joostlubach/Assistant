import UIKit

/// View displaying a tooltip.
open class TooltipView: UIView {

  public required init(tooltip: Tooltip) {
    self.tooltip = tooltip
    super.init(frame: CGRect.zero)

    setup()
  }
  public required init?(coder: NSCoder) {
    fatalError("TooltipView does not support NSCoding")
  }

  /// The tooltip to display.
  open let tooltip: Tooltip

  /// The target of the tooltip.
  open internal(set) var target: TooltipTarget!

  /// The spacing of this assignment.
  open var spacing: CGFloat = 0

  /// Whether or not to enable hovering for this view.
  open var hoverEnabled = false

  /// Whether or not to enable show/hide animations for this view.
  open var showHideAnimationEnabled = false

  open lazy var tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TooltipView.tap))

  // MARK: Setup

  open func setup() {
    addGestureRecognizer(tapRecognizer)
    isHidden = true
  }

  func tap() {
    tooltip.markAsSeen()
  }

  // MARK: - Alignment

  /// Aligns the tooltip with the target.
  func align() {
    precondition(superview != nil)
    precondition(target != nil, "You cannot add TooltipViews yourself. Use a TooltipProvider instead.")

    bounds.size.width = UIScreen.main.bounds.width
    sizeToFit()

    let anchorPoint = tooltip.anchorPointForSize(bounds.size)
    let targetRect = target.targetRectInView(superview!)
    let alignmentPoint = tooltip.alignmentPointForTargetRect(targetRect, spacing: spacing)

    center.x = alignmentPoint.x - anchorPoint.x + bounds.width / 2
    center.y = alignmentPoint.y - anchorPoint.y + bounds.height / 2

    if isHidden {
      show()
    }
  }

  // MARK: Show / remove

  /// Shows this tooltip view.
  func show() {
    if showHideAnimationEnabled {
      alpha = 0
      transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
      isHidden = false

      let options = UIViewAnimationOptions(rawValue: UInt(UIViewAnimationCurve.easeInOut.rawValue))
      UIView.animate(withDuration: 0.1, delay: 0.0, options: options, animations: {
        self.alpha = 1.0
        self.transform = CGAffineTransform.identity
      }, completion: { done in
        if done {
          self.resumeAnimations()
        }
      })
    } else {
      isHidden = false
      resumeAnimations()
    }
  }

  /// Hides this tooltip view, and subsequently removes it.
  open func remove() {
    if showHideAnimationEnabled {
      let options = UIViewAnimationOptions(rawValue: UInt(UIViewAnimationCurve.easeInOut.rawValue))
      UIView.animate(withDuration: 0.1, delay: 0.0, options: options, animations: {
        self.alpha = 0
        self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { _ in
          self.isHidden = true
          self.removeFromSuperview()
      })
    } else {
      isHidden = true
      removeFromSuperview()
    }
  }

  // MARK: Animations

  open func suspendAnimations() {
    if layer.animation(forKey: "hover") != nil {
      stopHover()
    }
  }

  open func resumeAnimations() {
    if hoverEnabled && layer.animation(forKey: "hover") == nil {
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
    animation.fromValue = NSValue(cgSize: CGSize.zero)
    animation.toValue = NSValue(cgSize: tooltip.hoverOffset)

    // Start the animation at random between 0 and 1.000.000 µs.
    let randomDelay = Double(arc4random() % 1000) / 1000
    animation.beginTime = CACurrentMediaTime() + randomDelay

    layer.add(animation, forKey: "hover")
  }

  private func stopHover() {
    layer.removeAnimation(forKey: "hover")
  }

}

extension Tooltip {

  /// The offset of the hover animation for a tooltip using this alignment.
  var hoverOffset: CGSize {
    switch alignment {
    case .none: return CGSize.zero
    case .top: return CGSize(width: 0, height: 2)
    case .bottom: return CGSize(width: 0, height: -2)
    case .left: return CGSize(width: 2, height: 0)
    case .right: return CGSize(width: -2, height: 0)
    }
  }

  /// Gets the alignment point (where the anchor of the tooltip should be placed) for the given target rectangle.
  ///
  /// - parameter rect:    The target rect.
  /// - parameter spacing: The space between the target view and the tooltip.
  /// - returns:       The alignment point.
  func alignmentPointForTargetRect(_ rect: CGRect, spacing: CGFloat) -> CGPoint {
    switch alignment {
    case .none:
      return CGPoint(x: rect.midX, y: rect.midY)
    case .top:
      return CGPoint(x: rect.midX, y: rect.minY - spacing)
    case .bottom:
      return CGPoint(x: rect.midX, y: rect.maxY + spacing)
    case .left:
      return CGPoint(x: rect.minX - spacing, y: rect.midY)
    case .right:
      return CGPoint(x: rect.maxX + spacing, y: rect.midY)
    }
  }

}
