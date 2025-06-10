import BitwardenKit
import Foundation

// MARK: - SharedTimeoutService

/// A service that manages account timeout between apps.
///
public protocol SharedTimeoutService {
    func clearTimeout(forUserId userId: String)

    func hasPassedTimeout(userId: String) -> Bool

    func updateTimeout(forUserId userId: String, lastActiveDate: Date?, timeoutLength: SessionTimeoutValue)
}

// MARK: - DefaultTimeoutService

public final class DefaultTimeoutService: SharedTimeoutService {
    public func clearTimeout(forUserId userId: String) {

    }
    
    public func hasPassedTimeout(userId: String) -> Bool {
        false
    }
    
    public func updateTimeout(forUserId userId: String, lastActiveDate: Date?, timeoutLength: SessionTimeoutValue) {

    }
}
