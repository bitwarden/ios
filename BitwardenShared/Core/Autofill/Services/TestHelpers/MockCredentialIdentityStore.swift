import AuthenticationServices

@testable import BitwardenShared

class MockCredentialIdentityStore: CredentialIdentityStore {
    var state = MockCredentialIdentityStoreState()
    var stateCalled = false

    var removeAllCredentialIdentitiesCalled = false
    var removeAllCredentialIdentitiesResult = Result<Void, Error>.success(())

    var replaceCredentialIdentitiesCalled = false
    var replaceCredentialIdentitiesIdentities: [CredentialIdentity]?
    var replaceCredentialIdentitiesResult = Result<Void, Error>.success(())

    func removeAllCredentialIdentities() async throws {
        removeAllCredentialIdentitiesCalled = true
        try removeAllCredentialIdentitiesResult.get()
    }

    @available(iOS 17, *)
    func replaceCredentialIdentities(_ identities: [ASCredentialIdentity]) async throws {
        replaceCredentialIdentitiesCalled = true
        replaceCredentialIdentitiesIdentities = identities.compactMap(CredentialIdentity.init)
        try replaceCredentialIdentitiesResult.get()
    }

    func replaceCredentialIdentities(with identities: [ASPasswordCredentialIdentity]) async throws {
        replaceCredentialIdentitiesCalled = true
        replaceCredentialIdentitiesIdentities = identities.compactMap(CredentialIdentity.init)
        try replaceCredentialIdentitiesResult.get()
    }

    func state() async -> ASCredentialIdentityStoreState {
        stateCalled = true
        return state
    }
}

// MARK: - MockCredentialIdentityStoreState

class MockCredentialIdentityStoreState: ASCredentialIdentityStoreState {
    var mockIsEnabled = true

    override var isEnabled: Bool {
        mockIsEnabled
    }
}

// MARK: - CredentialIdentity

enum CredentialIdentity: Equatable {
    case password(PasswordCredentialIdentity)

    init(identity: ASPasswordCredentialIdentity) {
        self = .password(PasswordCredentialIdentity(identity))
    }

    @available(iOS 17, *)
    init?(_ identity: ASCredentialIdentity) {
        switch identity {
        case let identity as ASPasswordCredentialIdentity:
            self = .password(PasswordCredentialIdentity(identity))
        default:
            return nil
        }
    }
}

// MARK: - PasswordCredentialIdentity

struct PasswordCredentialIdentity: Equatable {
    let id: String?
    let uri: String
    let username: String
}

extension PasswordCredentialIdentity {
    init(_ identity: ASPasswordCredentialIdentity) {
        id = identity.recordIdentifier
        uri = identity.serviceIdentifier.identifier
        username = identity.user
    }
}
