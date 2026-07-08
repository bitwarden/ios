import AuthenticationServices
import CryptoKit

/// Drives an `ASAuthorizationController` request and bridges its delegate callbacks to a Swift
/// concurrency continuation. Since the controller's `delegate` and `presentationContextProvider`
/// are weak references, this object owns the continuation itself so that calling `register(request:)`
/// as an async instance method keeps it alive (via the caller's `await`) for the life of the request,
/// without needing `objc_setAssociatedObject` to retain a separate delegate object.
///
@available(iOS 17, *)
public class CreatePasskeyCoordinator: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {
    // MARK: Private Properties

    private var continuation: CheckedContinuation<ASAuthorizationPlatformPublicKeyCredentialRegistration, Error>?
    private let window: ASPresentationAnchor

    // MARK: Initialization

    init(window: ASPresentationAnchor) {
        self.window = window
    }

    // MARK: Methods

    /// Performs the authorization request and suspends until the delegate receives a result.
    ///
    /// - Parameter request: The credential registration request to perform.
    /// - Returns: The completed passkey registration.
    ///
    func register(
        request: ASAuthorizationRequest,
    ) async throws -> ASAuthorizationPlatformPublicKeyCredentialRegistration {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: ASAuthorizationControllerDelegate

    public func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization,
    ) {
        defer { continuation = nil }
        guard let registration = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration
        else {
            continuation?.resume(throwing: PasskeyRegistrationError.missingAttestationObject)
            return
        }
        continuation?.resume(returning: registration)
    }

    public func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError error: Error,
    ) {
        defer { continuation = nil }
        continuation?.resume(throwing: error)
    }

    // MARK: ASAuthorizationControllerPresentationContextProviding

    public func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        window
    }
}
