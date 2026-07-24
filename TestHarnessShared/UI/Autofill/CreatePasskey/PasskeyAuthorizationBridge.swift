import AuthenticationServices

/// Drives an `ASAuthorizationController` request and bridges its delegate callbacks to a Swift
/// concurrency continuation. Since the controller's `delegate` and `presentationContextProvider`
/// are weak references, this object owns the continuation itself so that calling `perform(request:)`
/// as an async instance method keeps it alive (via the caller's `await`) for the life of the request,
/// without needing `objc_setAssociatedObject` to retain a separate delegate object.
///
/// Generic over the expected credential type so it can bridge both passkey registration
/// (`ASAuthorizationPlatformPublicKeyCredentialRegistration`) and assertion
/// (`ASAuthorizationPlatformPublicKeyCredentialAssertion`) requests.
///
@available(iOS 17, *)
class PasskeyAuthorizationBridge<Credential: ASAuthorizationCredential>: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {
    // MARK: Private Properties

    private var continuation: CheckedContinuation<Credential, Error>?
    private let window: ASPresentationAnchor

    // MARK: Initialization

    init(window: ASPresentationAnchor) {
        self.window = window
    }

    // MARK: Methods

    /// Performs the authorization request and suspends until the delegate receives a result.
    ///
    /// - Parameter request: The credential request to perform.
    /// - Returns: The completed passkey credential.
    ///
    func perform(request: ASAuthorizationRequest) async throws -> Credential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: ASAuthorizationControllerDelegate

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization,
    ) {
        defer { continuation = nil }
        guard let credential = authorization.credential as? Credential else {
            continuation?.resume(throwing: PasskeyAuthorizationBridgeError.unexpectedCredentialType)
            return
        }
        continuation?.resume(returning: credential)
    }

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError error: Error,
    ) {
        defer { continuation = nil }
        continuation?.resume(throwing: error)
    }

    // MARK: ASAuthorizationControllerPresentationContextProviding

    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        window
    }
}

// MARK: - PasskeyAuthorizationBridgeError

/// Errors that can occur while bridging an `ASAuthorizationController` request.
///
enum PasskeyAuthorizationBridgeError: Error, LocalizedError {
    /// The credential returned by the authorization controller was not the expected type.
    case unexpectedCredentialType

    var errorDescription: String? {
        switch self {
        case .unexpectedCredentialType:
            Localizations.unexpectedCredentialTypeReceived
        }
    }
}
