import Foundation

// MARK: - DateProvider

/// Methods that access the current date and time.
///
protocol DateProvider: Sendable {
    // MARK: Properties

    /// Returns a date instance that represents the current date and time, at the moment of access.
    var now: Date { get }
}

// MARK: - DefaultDateProvider

/// The default implementation of a `DateProvider`.
///
struct DefaultDateProvider: DateProvider {
    // MARK: Properties

    var now: Date { .now }
}
