import SwiftUI

// MARK: - Navigator

/// A protocol for an object that can navigate between screens and show alerts.
///
@MainActor
public protocol Navigator: AlertPresentable, AnyObject {
    // MARK: Properties

    /// The root view controller of this `Navigator`.
    var rootViewController: UIViewController { get }
}
