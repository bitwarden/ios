import SwiftUI

// MARK: - EmailAccessState

/// An object that defines the current state of a `EmailAccessView`.
///
struct EmailAccessState: Equatable, Sendable {
    // MARK: Properties

    /// Whether or not the user can delay setting up two-factor authentication.
    var allowDelay: Bool

    /// User-provided value for whether or not they can access their given email address.
    var canAccessEmail: Bool = false

    /// A model representing the data to display on a single page in the carousel.
    ///

//    enum Page: CaseIterable, Equatable, Identifiable {
//        case one
//        case two
//
//        var id: Self {
//            self
//        }
//    }
    // MARK: Properties

    /// The index of the currently visible page in the carousel.
    var currentPageIndex = 0
}
