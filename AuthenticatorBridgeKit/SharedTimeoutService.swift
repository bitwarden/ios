import BitwardenKit
import Foundation
import os

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

    public func clearTimeout(forUserId userId: String) {
        Logger.application.debug("DefaultSharedTimeoutService: clearTimeout(forUserId:)")
    }

    public func hasPassedTimeout(userId: String) -> Bool {
        Logger.application.debug("DefaultSharedTimeoutService: hasPassedTimeout(userId:)")
        return false
    }

    public func updateTimeout(forUserId userId: String, lastActiveDate: Date?, timeoutLength: SessionTimeoutValue) {
        Logger.application.debug("DefaultSharedTimeoutService: updateTimeout(forUserId:lastActiveDate:timeoutLength:)")
    }
}
