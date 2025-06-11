import AuthenticatorBridgeKit
import BitwardenKit
import Foundation

public final class MockSharedTimeoutService: SharedTimeoutService {
    var clearTimeoutUserIds = [String]()
    var clearTimeoutError: Error?
    var hasPassedTimeoutResult: Result<[String: Bool], Error> = .success([:])
    // swiftlint:disable:next large_tuple
    var updateTimeoutCalls: [(forUserId: String, lastActiveDate: Date?, timeoutLength: SessionTimeoutValue)] = []
    var updateTimeoutError: Error?

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
        timeoutLength: SessionTimeoutValue
    ) async throws {
        if let updateTimeoutError {
            throw updateTimeoutError
        }
        updateTimeoutCalls.append((forUserId: userId, lastActiveDate: lastActiveDate, timeoutLength: timeoutLength))
    }
}
