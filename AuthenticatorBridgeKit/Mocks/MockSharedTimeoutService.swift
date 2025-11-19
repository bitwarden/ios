import AuthenticatorBridgeKit
import BitwardenKit
import Foundation

public final class MockSharedTimeoutService: SharedTimeoutService {
    public var clearTimeoutUserIds = [String]()
    public var clearTimeoutError: Error?
    public var hasPassedTimeoutResult: Result<[String: Bool], Error> = .success([:])
    public var updateTimeoutUserId: String?
    public var updateTimeoutLastActiveDate: Date?
    public var updateTimeoutTimeoutLength: SessionTimeoutValue?
    public var updateTimeoutError: Error?

    public init() {}

    public func clearTimeout(forUserId userId: String) async throws {
        if let clearTimeoutError {
            throw clearTimeoutError
        }
        clearTimeoutUserIds.append(userId)
    }

    public func hasPassedTimeout(userId: String) async throws -> Bool {
        try hasPassedTimeoutResult.get()[userId] ?? false
    }

    public func updateTimeout(
        forUserId userId: String,
        lastActiveDate: Date?,
        timeoutLength: SessionTimeoutValue,
    ) async throws {
        if let updateTimeoutError {
            throw updateTimeoutError
        }
        updateTimeoutUserId = userId
        updateTimeoutLastActiveDate = lastActiveDate
        updateTimeoutTimeoutLength = timeoutLength
    }
}
