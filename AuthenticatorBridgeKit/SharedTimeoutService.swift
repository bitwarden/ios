import BitwardenKit
import Foundation

// MARK: - HasSharedTimeoutService

/// Protocol for an object that provides a `SharedTimeoutService`
///
public protocol HasSharedTimeoutService {
    /// The service for managing account timeout between apps.
    var sharedTimeoutService: SharedTimeoutService { get }
}

// MARK: - SharedTimeoutService

/// A service that manages account timeout between apps.
///
public protocol SharedTimeoutService {
    /// g
    func clearTimeout(forUserId userId: String)

    /// g
    func hasPassedTimeout(userId: String) -> Bool

    /// g
    func updateTimeout(forUserId userId: String, lastActiveDate: Date?, timeoutLength: SessionTimeoutValue)
}

// MARK: - DefaultTimeoutService

public final class DefaultSharedTimeoutService: SharedTimeoutService {
    public init() {}

    public func clearTimeout(forUserId userId: String) {}

    public func hasPassedTimeout(userId: String) -> Bool {
        false
    }

    public func updateTimeout(forUserId userId: String, lastActiveDate: Date?, timeoutLength: SessionTimeoutValue) {}
}
