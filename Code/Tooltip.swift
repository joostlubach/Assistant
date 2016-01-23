import UIKit

/// Represents one tooltip. Tooltips can be displayed using `TooltipView`. This class handles content
/// and invalidation.
public class Tooltip {

  // MARK: - Types

  /// Determines how the tooltip is aligned to its target.
  public enum Alignment {
    case None
    case Top, Bottom
    case Left, Right
  }


  // MARK: - Initialization

  /// Initializes the tooltip.
  ///
  /// - parameter name:        The name of the tooltip.
  /// - parameter showAfter:   Restrict this tooltip to show only after the other two have been marked as seen.
  /// - parameter bundleWith:  Bundle this tooltip with the given others, so that they are also marked as seen when this one is.
  public init(name: String, showAfter: [Tooltip] = [], bundleWith: [Tooltip] = []) {
    self.name = name
    self._showAfter = WeakSet(showAfter)
    self._bundleWith = WeakSet(bundleWith)

    // Create a full map between all tooltips in this bundling.
    for tooltip in bundleWith {
      for other in bundleWith + [self] {
        if other != tooltip {
          tooltip._bundleWith.insert(other)
        }
      }
    }
  }

  // MARK: Properties

  /// The name of the tooltip.
  public let name: String

  /// A list of tooltips which first have to have been marked as seen before this tooltip shows.
  public var showAfter: Set<Tooltip> {
    get { return Set(_showAfter) }
    set { _showAfter = WeakSet(newValue) }
  }

  private var _showAfter: WeakSet<Tooltip>

  /// A list of tooltips that are also marked as seen when this one is marked as seen.
  public var bundleWith: Set<Tooltip> {
    get { return Set(_bundleWith) }
    set { _bundleWith = WeakSet(newValue) }
  }

  // Note: store internally as WeakSet to prevent retention cycles.
  private var _bundleWith: WeakSet<Tooltip>

  /// The alignment of the tooltip (i.e. where is it placed relative to its target).
  public var alignment: Alignment {
    return .None
  }

  /// Gets the anchor point (the point of the tip of the arrow) relative to the top-left coordinate of a
  /// tooltip with this anchor alignment.
  ///
  /// - parameter size: The size of the tooltip.
  /// - returns:    The anchor point.
  public func anchorPointForSize(size: CGSize) -> CGPoint {
    switch alignment {
    case .None:
      return CGPointMake(size.width / 2, size.height / 2)
    case .Top:
      return CGPointMake(size.width / 2, size.height)
    case .Bottom:
      return CGPointMake(size.width / 2, 0)
    case .Left:
      return CGPointMake(size.width, size.height / 2)
    case .Right:
      return CGPointMake(0, size.height / 2)
    }
  }



  // MARK: - Tooltip static interface

  /// Provides a block that creates a view for a tooltip.
  public static var viewForTooltip: ((Tooltip) -> TooltipView)!

  // MARK: - Invalidation

  /// Determines whether this tooltip has already been seen. If so, it will not be added.
  public var seen: Bool {
    return SeenTooltipsUserDefault[name] ?? false
  }

  /// Determines whether this tooltip should be shown.
  public var shouldShow: Bool {
    if seen {
      return false
    } else {
      for tooltip in showAfter where !tooltip.seen {
        return false
      }
      return true
    }
  }

  /// Marks this tooltip as seen. It will immediately be removed.
  public func markAsSeen() {
    SeenTooltipsUserDefault[name] = true
    for tooltip in bundleWith {
      SeenTooltipsUserDefault[tooltip.name] = true
    }

    Tooltip.setNeedsUpdate()
  }

  /// Marks this tooltip as unseen. It may reappear as a result.
  public func markAsUnseen() {
    SeenTooltipsUserDefault[name] = nil
    for tooltip in bundleWith {
      SeenTooltipsUserDefault[tooltip.name] = nil
    }

    Tooltip.setNeedsUpdate()
  }

  /// Marks all tooltips as unseen, i.e. 'resets' the tooltips.
  public static func markAllAsUnseen() {
    SeenTooltipsUserDefault = [:]
    Tooltip.setNeedsUpdate()
  }

  // MARK: - Provision

  /// A list of tooltip providers.
  private static var providers = WeakSet<NSObject>()

  /// A list of currently assigned tooltips.
  private static var currentAssignments = [TooltipAssignment: TooltipView]()

  /// Adds a tooltip provider. The tooltips of this provider will immediately be shown, and shown until the tooltips are invalidated,
  /// or until the provider is removed.
  ///
  /// Typically, a provider is a `UIViewController`, which is added in `viewWillAppear(animated:)` and removed in `viewDidDisappear(animated:)`.
  public static func addProvider<T: TooltipProvider where T: NSObject>(provider: T) {
    providers.insert(provider)
    setNeedsUpdate()
  }

  /// Removes a previously added tooltip provider. Its tooltips are immediately removed.
  public static func removeProvider<T: TooltipProvider where T: NSObject>(provider: T) {
    providers.remove(provider)
    setNeedsUpdate()
  }

  /// Fetches all tooltips from all providers.
  private static func fetchAssignmentsFromProviders() -> [TooltipAssignment] {
    var result = [TooltipAssignment]()

    for object in providers {
      let provider = object as! TooltipProvider

      let provisioner = TooltipProvisioner(provider: provider)
      provider.provideTooltips(provisioner)

      // Add only those tooltips that haven't been seen yet.
      result += provisioner.assignments.filter { $0.tooltip.shouldShow }
    }

    return result
  }

  // MARK: Synchronization

  private static var needsUpdate = false
  private static var needsLayout = false

  /// Call this when tooltips need to be updated.
  public static func setNeedsUpdate() {
    needsUpdate = true
    needsLayout = true
    dispatch_async(dispatch_get_main_queue(), Tooltip.updateIfNeeded)
  }

  public static func setNeedsLayout() {
    needsLayout = true
    dispatch_async(dispatch_get_main_queue(), Tooltip.layoutIfNeeded)
  }

  /// Updates the tooltips if this is needed.
  public static func updateIfNeeded() {
    if needsUpdate {
      needsUpdate = false
      update()
    }
  }

  /// Lays out the tooltips if needed.
  public static func layoutIfNeeded() {
    if needsLayout {
      needsLayout = false
      layout()
    }
  }

  /// Synchronizes the tooltips so that the current list of provided tooltips is shown, and others are not. Existing tooltips are kept.
  private static func update() {
    let newAssignments = fetchAssignmentsFromProviders()

    var add    = [TooltipAssignment]()
    var remove = [TooltipAssignment]()

    // Check which assignments to add.
    for assignment in newAssignments {
      if currentAssignments[assignment] == nil {
        add.append(assignment)
      }
    }

    // Check which assignments to remove.
    for (assignment, _) in currentAssignments {
      if newAssignments.indexOf(assignment) == nil {
        remove.append(assignment)
      }
    }

    for assignment in add {
      currentAssignments[assignment] = createViewForAssignment(assignment)
    }
    for assignment in remove {
      currentAssignments[assignment]!.remove()
      currentAssignments[assignment] = nil
    }

    layoutIfNeeded()
    resumeAnimations()
    ensureObserverAdded()
  }

  /// Aligns all current tooltips.
  private static func layout() {
    for (_, view) in currentAssignments {
      view.align()
    }
  }


  // MARK: Views

  /// The view class to use when showing tooltips. Override to provide a custom class.
  public static var tooltipViewClass = TooltipView.self

  /// Creates a view for the given assignment.
  private static func createViewForAssignment(assignment: TooltipAssignment) -> TooltipView {
    precondition(viewForTooltip != nil, "You need to provide a TooltipView creation block")

    let view = viewForTooltip(assignment.tooltip)
    view.target = assignment.target
    if let spacing = assignment.spacing {
      view.spacing = spacing
    }

    assignment.provider.tooltipContainerView.addSubview(view)
    return view
  }

  /// Obtains all views for this tooltip that were provided by the given provider.
  public func viewsForProvider(provider: TooltipProvider) -> [TooltipView] {
    var views = [TooltipView]()

    for (assignment, view) in Tooltip.currentAssignments {
      if assignment.tooltip == self && assignment.provider === provider {
        views.append(view)
      }
    }

    return views
  }

  // MARK: Animations

  /// Suspends animations for all current tooltips.
  public static func suspendAnimations() {
    for (_, view) in currentAssignments {
      view.suspendAnimations()
    }
  }

  /// Suspends all tooltip animations that are visible.
  public static func resumeAnimations() {
    for (_, view) in currentAssignments {
      view.resumeAnimations()
    }
  }


  // MARK: - Application observing

  class ApplicationObserver: NSObject {
    func applicationDidBecomeActive() {
      Tooltip.resumeAnimations()
    }
  }

  private static var observer: ApplicationObserver!

  static func ensureObserverAdded() {
    if observer == nil {
      addObserver()
    }
  }

  static func addObserver() {
    observer = ApplicationObserver()

    let notificationCenter = NSNotificationCenter.defaultCenter()
    notificationCenter.addObserver(observer, selector: "applicationDidBecomeActive", name: UIApplicationDidBecomeActiveNotification, object: nil)
  }

  static func removeObserver() {
    if observer == nil {
      return
    }

    let notificationCenter = NSNotificationCenter.defaultCenter()
    notificationCenter.removeObserver(observer)
    observer = nil
  }

}

extension Tooltip: Hashable, Equatable {

  public var hashValue: Int {
    return name.hashValue
  }

}

public func ==(lhs: Tooltip, rhs: Tooltip) -> Bool {
  return lhs.name == rhs.name
}

private let SeenTooltipsUserDefaultKey = "co.mosdev.MDKit.SeenTooltips"

private var SeenTooltipsUserDefault: [String: Bool] {
  get {
    let userDefaults = NSUserDefaults.standardUserDefaults()
    return (userDefaults.dictionaryForKey(SeenTooltipsUserDefaultKey) as? [String: Bool]) ?? [:]
  }
  set {
    let userDefaults = NSUserDefaults.standardUserDefaults()
    userDefaults.setObject(newValue, forKey: SeenTooltipsUserDefaultKey)
  }
}