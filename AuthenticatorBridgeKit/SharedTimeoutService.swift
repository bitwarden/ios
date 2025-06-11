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
    func clearTimeout(forUserId userId: String) async throws

    /// g
    func hasPassedTimeout(userId: String) async throws -> Bool

    /// g
    func updateTimeout(forUserId userId: String, lastActiveDate: Date?, timeoutLength: SessionTimeoutValue) async throws
}

// MARK: - DefaultTimeoutService

public final class DefaultSharedTimeoutService: SharedTimeoutService {
    /// A repository for managing keychain items to be shared between Password Manager and Authenticator.
    private let sharedKeychainRepository: SharedKeychainRepository

    public init(sharedKeychainRepository: SharedKeychainRepository) {
        self.sharedKeychainRepository = sharedKeychainRepository
    }

    public func clearTimeout(forUserId userId: String) async throws {
        Logger.application.debug("DefaultSharedTimeoutService: clearTimeout(forUserId:)")
        try await sharedKeychainRepository.setAccountAutoLogoutTime(nil, userId: userId)
    }

    public func hasPassedTimeout(userId: String) async throws -> Bool {
        Logger.application.debug("DefaultSharedTimeoutService: hasPassedTimeout(userId:\(userId))")
        return false
    }

    public func updateTimeout(
        forUserId userId: String,
        lastActiveDate: Date?,
        timeoutLength: SessionTimeoutValue
    ) async throws {
        Logger.application.debug("DefaultSharedTimeoutService: updateTimeout(forUserId:lastActiveDate:timeoutLength:)")

        guard let lastActiveDate else {
            try await clearTimeout(forUserId: userId)
            return
        }

        let timeout = lastActiveDate.addingTimeInterval(TimeInterval(timeoutLength.seconds))

        try await sharedKeychainRepository.setAccountAutoLogoutTime(timeout, userId: userId)
    }
}
