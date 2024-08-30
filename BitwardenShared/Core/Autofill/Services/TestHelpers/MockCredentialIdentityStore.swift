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
    case passkey(PasskeyCredentialIdentity)
    case oneTimeCode(OneTimeCodeCredentialIdentity)

    @available(iOS 17.0, *)
    var asCredentialIdentity: ASCredentialIdentity? {
        switch self {
        case let .password(passwordIdentity):
            return ASPasswordCredentialIdentity(
                serviceIdentifier: ASCredentialServiceIdentifier(
                    identifier: passwordIdentity.uri,
                    type: .URL
                ),
                user: passwordIdentity.username,
                recordIdentifier: passwordIdentity.id
            )
        case let .passkey(passkeyIdentity):
            return ASPasskeyCredentialIdentity(
                relyingPartyIdentifier: passkeyIdentity.relyingPartyIdentifier,
                userName: passkeyIdentity.userName,
                credentialID: passkeyIdentity.credentialID,
                userHandle: passkeyIdentity.userHandle,
                recordIdentifier: passkeyIdentity.recordIdentifier
            )
        default:
            #if compiler(>=6)
            if #available(iOS 18, *), case let .oneTimeCode(oneTimeCodeIdentity) = self {
                return ASOneTimeCodeCredentialIdentity(
                    serviceIdentifier: ASCredentialServiceIdentifier(
                        identifier: oneTimeCodeIdentity.serviceIdentifier,
                        type: .URL
                    ),
                    label: oneTimeCodeIdentity.label,
                    recordIdentifier: oneTimeCodeIdentity.recordIdentifier
                )
            } else {
                return nil
            }
            #else
            return nil
            #endif
        }
    }

    init(identity: ASPasswordCredentialIdentity) {
        self = .password(PasswordCredentialIdentity(identity))
    }

    @available(iOS 17, *)
    init?(_ identity: ASCredentialIdentity) {
        switch identity {
        case let identity as ASPasswordCredentialIdentity:
            self = .password(PasswordCredentialIdentity(identity))
        case let passkeyIdentity as ASPasskeyCredentialIdentity:
            self = .passkey(PasskeyCredentialIdentity(passkeyIdentity))
        default:
            #if compiler(>=6)
            if #available(iOS 18, *), let oneTimeCodeIdentity = identity as? ASOneTimeCodeCredentialIdentity {
                self = .oneTimeCode(OneTimeCodeCredentialIdentity(oneTimeCodeIdentity))
            } else {
                return nil
            }
            #else
            return nil
            #endif
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

// MARK: - PasskeyCredentialIdentity

struct PasskeyCredentialIdentity: Equatable {
    let credentialID: Data
    let recordIdentifier: String?
    let relyingPartyIdentifier: String
    let userHandle: Data
    let userName: String
}

extension PasskeyCredentialIdentity {
    @available(iOS 17.0, *)
    init(_ identity: ASPasskeyCredentialIdentity) {
        credentialID = identity.credentialID
        recordIdentifier = identity.recordIdentifier
        relyingPartyIdentifier = identity.relyingPartyIdentifier
        userHandle = identity.userHandle
        userName = identity.userName
    }
}

// MARK: - OneTimeCodeCredentialIdentity

struct OneTimeCodeCredentialIdentity: Equatable {
    let label: String
    let recordIdentifier: String?
    let serviceIdentifier: String
}

#if compiler(>=6)
extension OneTimeCodeCredentialIdentity {
    @available(iOS 18.0, *)
    init(_ identity: ASOneTimeCodeCredentialIdentity) {
        label = identity.label
        recordIdentifier = identity.recordIdentifier
        serviceIdentifier = identity.serviceIdentifier.identifier
    }
}
#endif
