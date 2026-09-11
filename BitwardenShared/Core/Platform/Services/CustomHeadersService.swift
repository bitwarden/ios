import BitwardenKit
import Foundation

// MARK: - CustomHeadersService

/// A service for managing custom headers sent with requests to a self-hosted environment.
///
protocol CustomHeadersService: AnyObject { // sourcery: AutoMockable
    /// Gets the custom headers for the current environment.
    ///
    /// The environment service determines which URLs are active (pre-auth or logged-in account),
    /// so this returns the correct headers for the current context.
    ///
    /// - Returns: The custom headers, or an empty dictionary if none are configured.
    ///
    func getCustomHeaders() async -> [String: String]

    /// Gets the custom headers stored in the Keychain with the given identifier.
    ///
    /// - Parameter id: The identifier of the custom headers.
    /// - Returns: The custom headers, or an empty dictionary if none are stored.
    ///
    /// sourcery: useSelectorName
    func getCustomHeaders(id: String) async throws -> [String: String]

    /// Removes the custom headers with the given identifier from the Keychain if no other account
    /// still references them.
    ///
    /// - Parameter id: The identifier of the custom headers to remove.
    ///
    /// sourcery: useSelectorName
    func removeCustomHeaders(id: String) async throws

    /// Removes the custom headers for a specific user account.
    ///
    /// Used during account logout to clean up custom header data. Reads the identifier from the
    /// account's stored environment URLs and deletes the Keychain item only if no other account
    /// still references it.
    ///
    /// - Parameter userId: The user ID of the account being removed.
    ///
    /// sourcery: useSelectorName
    func removeCustomHeaders(userId: String) async throws

    /// Stores custom headers in the Keychain and returns the identifier under which they were saved.
    ///
    /// - Parameter headers: The custom headers to store.
    /// - Returns: The identifier of the stored custom headers.
    ///
    func saveCustomHeaders(_ headers: [String: String]) async throws -> String
}

// MARK: - DefaultCustomHeadersService

/// Default implementation of the `CustomHeadersService`.
///
final class DefaultCustomHeadersService: CustomHeadersService {
    // MARK: Private Properties

    /// Backing store for the cached headers of the most recently resolved identifier. Access via `lock`.
    private nonisolated(unsafe) var cachedHeaders: (id: String, headers: [String: String])?

    /// The service used to manage environment URLs (handles pre-auth vs active account).
    private let environmentService: EnvironmentService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The repository used to store the header data in the keychain.
    private let keychainRepository: KeychainRepository

    /// Lock protecting the cached headers accessed from concurrent async tasks.
    private let lock = NSLock()

    /// The service used to manage application state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultCustomHeadersService`.
    ///
    /// - Parameters:
    ///   - environmentService: The service used to manage environment URLs.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - keychainRepository: The repository used to store the header data in the Keychain.
    ///   - stateService: The service used to manage application state.
    ///
    init(
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        keychainRepository: KeychainRepository,
        stateService: StateService,
    ) {
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.keychainRepository = keychainRepository
        self.stateService = stateService
    }

    // MARK: Methods

    func getCustomHeaders() async -> [String: String] {
        guard let id = environmentService.customHeadersId, !id.isEmpty else {
            return [:]
        }
        if let cached = lock.withLock({ cachedHeaders }), cached.id == id {
            return cached.headers
        }
        do {
            let headers = try await getCustomHeaders(id: id)
            lock.withLock { cachedHeaders = (id: id, headers: headers) }
            return headers
        } catch {
            errorReporter.log(error: error)
            return [:]
        }
    }

    func getCustomHeaders(id: String) async throws -> [String: String] {
        try await keychainRepository.getCustomHeaders(id: id) ?? [:]
    }

    func removeCustomHeaders(id: String) async throws {
        // Only delete the Keychain item if no other account still references these headers.
        let inUse = await isIdInUse(id)
        if !inUse {
            try await keychainRepository.deleteCustomHeaders(id: id)
            lock.withLock {
                if cachedHeaders?.id == id {
                    cachedHeaders = nil
                }
            }
        }
    }

    func removeCustomHeaders(userId: String) async throws {
        // Read the identifier from the account's stored environment URLs.
        let environmentURLs = try await stateService.getEnvironmentURLs(userId: userId)
        guard let id = environmentURLs?.customHeadersId else { return }

        // Only delete the Keychain item if no other account still references these headers.
        let inUse = await isIdInUse(id, excludingUserId: userId)
        if !inUse {
            try await keychainRepository.deleteCustomHeaders(id: id)
            lock.withLock {
                if cachedHeaders?.id == id {
                    cachedHeaders = nil
                }
            }
        }
    }

    func saveCustomHeaders(_ headers: [String: String]) async throws -> String {
        let id = UUID().uuidString
        try await keychainRepository.setCustomHeaders(headers, id: id)
        lock.withLock { cachedHeaders = (id: id, headers: headers) }
        return id
    }

    // MARK: Private

    /// Returns whether any account's environment URLs still reference the given identifier.
    ///
    /// - Parameters:
    ///   - id: The custom headers identifier to check.
    ///   - excludingUserId: An optional user ID to exclude from the check (e.g., the account being removed).
    ///
    private func isIdInUse(_ id: String, excludingUserId: String? = nil) async -> Bool {
        // Check the pre-auth environment URLs.
        let preAuthURLs = await stateService.getPreAuthEnvironmentURLs()
        if preAuthURLs?.customHeadersId == id {
            return true
        }

        // Check all regular accounts' environment URLs.
        let accounts = await (try? stateService.getAccounts()) ?? []
        for account in accounts {
            let accountUserId = account.profile.userId
            if let excludingUserId, accountUserId == excludingUserId { continue }
            let accountURLs = try? await stateService.getEnvironmentURLs(userId: accountUserId)
            if accountURLs?.customHeadersId == id { return true }
        }

        return false
    }
}
