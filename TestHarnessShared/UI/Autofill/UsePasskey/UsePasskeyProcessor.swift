import AuthenticationServices
import BitwardenKit
import Combine
import UIKit

// MARK: - UsePasskeyProcessor

/// The processor for the use passkey test screen.
///
class UsePasskeyProcessor: StateProcessor<
    UsePasskeyState,
    UsePasskeyAction,
    UsePasskeyEffect,
> {
    // MARK: Types

    typealias Services = HasErrorReporter

    typealias PerformAssertion = (_ rpId: String) async throws -> Void

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    /// A delegate used to obtain a presentation anchor for the passkey sheet.
    private weak var delegate: UsePasskeyProcessorDelegate?

    // MARK: Internal for Testability

    /// Performs the passkey assertion flow. Overridable in tests.
    var performAssertion: PerformAssertion

    // MARK: Initialization

    init(
        coordinator: AnyCoordinator<RootRoute, Void>,
        delegate: UsePasskeyProcessorDelegate?,
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        performAssertion = { _ in throw PasskeyAssertionError.notAvailable }
        super.init(state: UsePasskeyState())

        performAssertion = { [weak self] rpId in
            try await self?.performPasskeyAssertion(rpId: rpId)
        }
    }

    // MARK: Methods

    override func receive(_ action: UsePasskeyAction) {
        switch action {
        case let .rpIdChanged(newValue): state.rpId = newValue
        }
    }

    override func perform(_ effect: UsePasskeyEffect) async {
        switch effect {
        case .assertPasskey: await assertPasskey()
        }
    }

    // MARK: Private

    private func assertPasskey() async {
        state.status = .inProgress
        do {
            try await performAssertion(state.rpId)
            state.status = .success
        } catch {
            state.status = .failure(error.localizedDescription)
        }
    }

    private func performPasskeyAssertion(rpId: String) async throws {
        guard #available(iOS 17, *) else { throw PasskeyAssertionError.notAvailable }

        let window = await delegate?.presentationAnchorForPasskeyAssertion() ?? UIWindow()
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let challenge = Data((0 ..< 32).map { _ in UInt8.random(in: 0 ... 255) })
        let request = provider.createCredentialAssertionRequest(challenge: challenge)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let handler = PasskeyAssertionHandler(continuation: continuation, window: window)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = handler
            controller.presentationContextProvider = handler
            objc_setAssociatedObject(controller, &passkeyContinuationKey, handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            controller.performRequests()
        }
    }
}

// MARK: - UsePasskeyProcessorDelegate

/// A delegate that provides a presentation anchor for the passkey assertion sheet.
///
protocol UsePasskeyProcessorDelegate: AnyObject {
    /// Returns the window to use as the presentation anchor for the passkey assertion sheet.
    @MainActor
    func presentationAnchorForPasskeyAssertion() async -> ASPresentationAnchor
}

// MARK: - PasskeyAssertionError

enum PasskeyAssertionError: Error, LocalizedError {
    case notAvailable
    case unexpectedCredentialType

    var errorDescription: String? {
        switch self {
        case .notAvailable: Localizations.passkeyAssertionNotAvailable
        case .unexpectedCredentialType: "Unexpected credential type received from the authorization controller."
        }
    }
}

// MARK: - PasskeyAssertionHandler

@available(iOS 17, *)
private class PasskeyAssertionHandler: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<Void, Error>
    private let window: ASPresentationAnchor

    init(continuation: CheckedContinuation<Void, Error>, window: ASPresentationAnchor) {
        self.continuation = continuation
        self.window = window
    }

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization _: ASAuthorization,
    ) {
        continuation.resume()
    }

    func authorizationController(controller _: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }

    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        window
    }
}

// MARK: - Private Globals

private var passkeyContinuationKey: UInt8 = 0
