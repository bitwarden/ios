import BitwardenKit
import BitwardenSdk
import Foundation

// MARK: - ClientBuilder

/// A protocol for creating a new `BitwardenSdkClient`.
///
protocol ClientBuilder {
    /// Creates a `BitwardenSdkClient`.
    ///
    /// - Returns: A new `BitwardenSdkClient`.
    ///
    func buildClient() async -> BitwardenSdkClient
}

// MARK: - DefaultClientBuilder

/// A default `ClientBuilder` implementation.
///
class DefaultClientBuilder: ClientBuilder {
    // MARK: Properties

    /// The service used by the application to manage the app's ID.
    private let appIDService: AppIDService

    /// The service used by the application to manage the environment settings.
    private let environmentService: EnvironmentService

    /// The token provider to pass to the SDK.
    private let tokenProvider: ClientManagedTokens

    /// The user agent builder to pass to the SDK.
    private let userAgentBuilder: UserAgentBuilder

    // MARK: Initialization

    /// Initializes a new client.
    ///
    /// - Parameters:
    ///   - appIDService: The service used by the application to manage the app's ID.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - tokenProvider: The token provider to pass to the SDK.
    ///   - userAgentBuilder: The user agent builder used to construct the user agent string.
    init(
        appIDService: AppIDService,
        environmentService: EnvironmentService,
        tokenProvider: ClientManagedTokens,
        userAgentBuilder: UserAgentBuilder,
    ) {
        self.appIDService = appIDService
        self.environmentService = environmentService
        self.tokenProvider = tokenProvider
        self.userAgentBuilder = userAgentBuilder
    }

    // MARK: Methods

    func buildClient() async -> BitwardenSdkClient {
        let deviceIdentifier = await appIDService.getOrCreateAppID()
        let settings = ClientSettings(
            identityUrl: environmentService.identityURL.absoluteString,
            apiUrl: environmentService.apiURL.absoluteString,
            userAgent: userAgentBuilder.value,
            deviceType: .iOs,
            deviceIdentifier: deviceIdentifier,
            bitwardenClientVersion: Bundle.main.appVersion,
            bitwardenPackageType: nil,
        )
        return Client(tokenProvider: tokenProvider, settings: settings)
    }
}
