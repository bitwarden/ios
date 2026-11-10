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

// MARK: - ClientSettingsValidator

/// A protocol for checking environment settings with the SDK before they're saved.
///
protocol ClientSettingsValidator: AnyObject { // sourcery: AutoMockable
    /// Checks the SDK client settings and client certificate that `urls` would produce.
    ///
    /// - Parameter urls: The environment URLs and client certificate the user entered.
    /// - Throws: `BitwardenSdk.BitwardenError.ValidateClientSettings` if the SDK rejects the
    ///   settings, or `ClientCertificateError.invalidCertificate` if the certificate's Keychain
    ///   identity can't be read.
    ///
    func validateSettings(urls: EnvironmentURLData) async throws
}

// MARK: - DefaultClientBuilder

/// A default `ClientBuilder` and `ClientSettingsValidator` implementation.
///
class DefaultClientBuilder: ClientBuilder, ClientSettingsValidator {
    // MARK: Properties

    /// The service used by the application to manage the app's ID.
    private let appIDService: AppIDService

    /// The service used to look up the client certificate for mTLS authentication.
    private let clientCertificateService: ClientCertificateService

    /// The service used by the application to manage the environment settings.
    private let environmentService: EnvironmentService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The token provider to pass to the SDK.
    private let tokenProvider: ClientManagedTokens

    /// The user agent builder to pass to the SDK.
    private let userAgentBuilder: UserAgentBuilder

    // MARK: Initialization

    /// Initializes a new client.
    ///
    /// - Parameters:
    ///   - appIDService: The service used by the application to manage the app's ID.
    ///   - clientCertificateService: The service used to look up the client certificate for mTLS
    ///     authentication.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - tokenProvider: The token provider to pass to the SDK.
    ///   - userAgentBuilder: The user agent builder used to construct the user agent string.
    init(
        appIDService: AppIDService,
        clientCertificateService: ClientCertificateService,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        tokenProvider: ClientManagedTokens,
        userAgentBuilder: UserAgentBuilder,
    ) {
        self.appIDService = appIDService
        self.clientCertificateService = clientCertificateService
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.tokenProvider = tokenProvider
        self.userAgentBuilder = userAgentBuilder
    }

    // MARK: Methods

    func buildClient() async -> BitwardenSdkClient {
        let settings = await clientSettings(
            identityURL: environmentService.identityURL,
            apiURL: environmentService.apiURL,
        )
        // A fresh `ManagedSettingsBindingClient` carries no management profile. The app doesn't
        // consume the SDK's managed settings channel; MDM configuration is read directly from the
        // `com.apple.configuration.managed` user defaults domain in `EnvironmentService`.
        return await Client(
            tokenProvider: tokenProvider,
            settings: settings,
            managedSettings: ManagedSettingsBindingClient(),
            clientCertificate: clientCertificate(),
        )
    }

    func validateSettings(urls: EnvironmentURLData) async throws {
        let environmentURLs = EnvironmentURLs(environmentURLData: urls)
        let settings = await clientSettings(
            identityURL: environmentURLs.identityURL,
            apiURL: environmentURLs.apiURL,
        )
        var certificate: ClientCertificate?
        if let fingerprint = urls.clientCertificateFingerprint?.nilIfEmpty {
            do {
                guard let identity = try await clientCertificateService.getClientCertificateIdentity(
                    fingerprint: fingerprint,
                ) else {
                    throw ClientCertificateError.invalidCertificate
                }
                certificate = try ClientCertificate(identity: identity)
            } catch {
                errorReporter.log(error: error)
                throw ClientCertificateError.invalidCertificate
            }
        }
        try validateClientSettings(settings: settings, clientCertificate: certificate)
    }

    // MARK: Private

    /// Builds the SDK client certificate from the current environment's identity, if one is set.
    ///
    /// The SDK binds the certificate for the client's lifetime. That's safe because the environment
    /// only changes before login, where `ClientService` builds a new client for every call.
    ///
    /// - Returns: The client certificate, or `nil` if none is set or it can't be used.
    ///
    private func clientCertificate() async -> ClientCertificate? {
        guard let identity = await clientCertificateService.getClientCertificateIdentity() else {
            return nil
        }
        do {
            return try ClientCertificate(identity: identity)
        } catch {
            errorReporter.log(error: error)
            return nil
        }
    }

    /// Builds the SDK client settings for a server.
    ///
    /// - Parameters:
    ///   - identityURL: The URL for the identity API.
    ///   - apiURL: The URL for the API.
    /// - Returns: The settings for an SDK client that targets the server.
    ///
    private func clientSettings(identityURL: URL, apiURL: URL) async -> ClientSettings {
        let deviceIdentifier = await appIDService.getOrCreateAppID()
        return ClientSettings(
            identityUrl: identityURL.absoluteString,
            apiUrl: apiURL.absoluteString,
            userAgent: userAgentBuilder.value,
            deviceType: .iOs,
            deviceIdentifier: deviceIdentifier,
            bitwardenClientVersion: Bundle.main.appVersion,
            bitwardenPackageType: nil,
        )
    }
}
