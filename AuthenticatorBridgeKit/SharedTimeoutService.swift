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
    /// Clears the shared timeout for a user.
    /// - Parameters:
    ///   - userId: The user's ID
    func clearTimeout(forUserId userId: String) async throws

    /// Determines if a user has passed their timeout, using the current time and the saved shared time.
    /// If the current time is equal to the timeout time, then it is considered passed. If there is no
    /// saved time, then this will always return false.
    /// - Parameters:
    ///   - userId: The user's ID
    /// - Returns: whether or not the user has passed their timeout
    func hasPassedTimeout(userId: String) async throws -> Bool

    /// Updates the shared timeout for a user.
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - lastActiveDate: The last time the user was active
    ///   - timeoutLength: The user's preferred timeout length
    func updateTimeout(forUserId userId: String, lastActiveDate: Date?, timeoutLength: SessionTimeoutValue) async throws
}

// MARK: - DefaultTimeoutService

public final class DefaultSharedTimeoutService: SharedTimeoutService {
    /// A repository for managing keychain items to be shared between Password Manager and Authenticator.
    private let sharedKeychainRepository: SharedKeychainRepository

    /// A service for providing the current time.
    private let timeProvider: TimeProvider

    public init(
        sharedKeychainRepository: SharedKeychainRepository,
        timeProvider: TimeProvider,
    ) {
        self.sharedKeychainRepository = sharedKeychainRepository
        self.timeProvider = timeProvider
    }

    public func clearTimeout(forUserId userId: String) async throws {
        try await sharedKeychainRepository.setAccountAutoLogoutTime(nil, userId: userId)
    }

    public func hasPassedTimeout(userId: String) async throws -> Bool {
        guard let autoLogoutTime = try await sharedKeychainRepository.getAccountAutoLogoutTime(userId: userId) else {
            return false
        }
        return timeProvider.presentTime >= autoLogoutTime
    }

    public func updateTimeout(
        forUserId userId: String,
        lastActiveDate: Date?,
        timeoutLength: SessionTimeoutValue,
    ) async throws {
        guard let lastActiveDate else {
            try await clearTimeout(forUserId: userId)
            return
        }

        let timeout = lastActiveDate.addingTimeInterval(TimeInterval(timeoutLength.seconds))

        try await sharedKeychainRepository.setAccountAutoLogoutTime(timeout, userId: userId)
    }
}
