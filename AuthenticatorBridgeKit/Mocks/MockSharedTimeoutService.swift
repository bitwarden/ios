import AuthenticatorBridgeKit
import BitwardenKit
import Foundation

public final class MockSharedTimeoutService: SharedTimeoutService {
    public func clearTimeout(forUserId userId: String) {

    }
    
    public func hasPassedTimeout(userId: String) -> Bool {
        false
    }
    
    public func updateTimeout(forUserId userId: String, lastActiveDate: Date?, timeoutLength: SessionTimeoutValue) {

    }

    public init () {

    }
}
