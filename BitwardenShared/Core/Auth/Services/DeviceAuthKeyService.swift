import CryptoKit
import Combine
import Foundation
import os.log

import BitwardenSdk

// MARK: DeviceAuthKeyService

/// Service to manage the device passkey.
protocol DeviceAuthKeyService {
    /// Create device passkey with PRF encryption key.
    ///
    /// Before calling, vault must be unlocked to wrap user encryption key.
    ///  - Parameters:
    ///      - masterPasswordHash: Master password hash suitable for server authentication.
    ///      - overwrite: Whether to overwrite an existing value if a previous one is already found.
    ///      - userId: Currently active user ID for the account.
    func createDeviceAuthKey(
        masterPasswordHash: String,
        overwrite: Bool,
        userId: String
    ) async throws -> DeviceAuthKeyRecord
    
    /// Signs a passkey assertion request with the device auth key, if it exists and matches the given
    /// ``recordIdentifier``.
    ///
    ///  - Parameters:
    ///      - request: The passkey assertion request.
    ///      - recordIdentifier: The recordIdentifer for the ``ASPasskeyCredentialIdentity``  related to the passkey
    ///                    assertion request,  which should be equal to the cipher ID of the device auth key record.
    ///      - userId: Currently active user ID for the account.
    /// - Returns: A ``GetAssertionResult``, or ``nil`` if the device auth key does not exist.
    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
        userId: String
    ) async throws -> GetAssertionResult?
    
    /// Retrieve the metadata for the device passkey, if it exists.
    ///
    ///  - Parameters:
    ///      - userId: Currently active user ID for the account.
    func getDeviceAuthKeyMetadata(userId: String) async throws -> DeviceAuthKeyMetadata?

    /// A publisher for the device auth key
    func deviceAuthKeyPublisher() -> AnyPublisher<[String: Bool], Never>
}

/// Implementation fo DeviceAuthKeyService
struct DefaultDeviceAuthKeyService: DeviceAuthKeyService {
    // MARK: Properties

    private let keychainRepository: KeychainRepository
    /// A subject containing a userId and flag for the presence of the unlock passkey for logged in accounts.
    private let deviceAuthKeySubject = CurrentValueSubject<[String: Bool], Never>([:])

    // MARK: Initializers

    init(
        keychainRepository: KeychainRepository,
    ) {
        self.keychainRepository = keychainRepository
    }

    // MARK: Functions

    func createDeviceAuthKey(
        masterPasswordHash: String,
        overwrite: Bool,
        userId: String,
    ) async throws -> DeviceAuthKeyRecord {
        var curVal = deviceAuthKeySubject.value
        curVal[userId] = true
        deviceAuthKeySubject.send(curVal)

        throw DeviceAuthKeyError.notImplemented
    }

    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
        userId: String
    ) async throws -> GetAssertionResult? {
        throw DeviceAuthKeyError.notImplemented
    }
    
    func getDeviceAuthKeyMetadata(userId: String) async throws -> DeviceAuthKeyMetadata? {
        guard let json = try? await keychainRepository.getDeviceAuthKeyMetadata(userId: userId) else {
            return nil
        }
        
        guard let jsonData = json.data(using: .utf8) else {
            return nil
        }
        
        let metadata: DeviceAuthKeyMetadata = try JSONDecoder.defaultDecoder.decode(
            DeviceAuthKeyMetadata.self,
            from: jsonData
        )
        Logger.application.debug("Metadata: \(json) })")
        return metadata
    }

    // MARK: Private
    
    /// Retrieve the device auth key secrets, if the record exists.
    ///
    /// Before calling, vault must be unlocked to wrap user encryption key.
    ///  - Parameters:
    ///      - userId: User ID for the account to fetch.
    private func getDeviceAuthKeyRecord(userId: String) async throws -> DeviceAuthKeyRecord? {
        guard let json = try? await keychainRepository.getDeviceAuthKey(userId: userId) else {
            return nil
        }
        
        guard let jsonData = json.data(using: .utf8) else {
            return nil
        }
        
        let record: DeviceAuthKeyRecord = try JSONDecoder.defaultDecoder.decode(
            DeviceAuthKeyRecord.self,
            from: jsonData
        )
        Logger.application.debug("Record: \(json) })")
        return record
    }

    // MARK: Publishers

    func deviceAuthKeyPublisher() -> AnyPublisher<[String: Bool], Never> {
        deviceAuthKeySubject.eraseToAnyPublisher()
    }
}

enum DeviceAuthKeyError: Error {
    case notImplemented
    case missingOrInvalidKey
}
