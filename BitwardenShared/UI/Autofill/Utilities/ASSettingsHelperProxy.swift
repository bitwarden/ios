import AuthenticationServices

// MARK: - ASSettingsHelperProxy

/// A proxy protocol to call ``ASSettingsHelper`` functions so it can be mocked.
///
protocol ASSettingsHelperProxy { // sourcery: AutoMockable
    /// Calling this method will open the Settings app and navigate directly to the Verification Code provider settings.
    @available(iOS 17.0, *)
    func openVerificationCodeAppSettings() async throws

    /// Call this method from your containing app to request to turn on a contained Credential Provider Extension.
    /// If the extension is not currently enabled, a prompt will be shown to allow it to be turned on.
    /// Returns whether the credential provider extension is enabled.
    @available(iOS 18.0, *)
    func requestToTurnOnCredentialProviderExtension() async -> Bool
}

/// Default implementation of ``ASSettingsHelperProxy``.
///
class DefaultASSettingsHelperProxy: ASSettingsHelperProxy {
    // MARK: Methods

    @available(iOS 17.0, *)
    func openVerificationCodeAppSettings() async throws {
        try await ASSettingsHelper.openVerificationCodeAppSettings()
    }

    @available(iOS 18.0, *)
    func requestToTurnOnCredentialProviderExtension() async -> Bool {
        await ASSettingsHelper.requestToTurnOnCredentialProviderExtension()
    }
}
