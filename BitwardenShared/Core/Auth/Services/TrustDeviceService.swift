import BitwardenSdk
import CryptoKit
import Foundation

/// A protocol for a service used to handle the trusted device encryption logic.
///
protocol TrustDeviceService {
    /// Gets the current device key if device is trusted.
    ///
    /// - Returns: A string value for the device key if it exists.
    ///
    func getDeviceKey() async throws -> String?

    /// Creates and stores device keys making the device trusted.
    ///
    /// - Returns: A object containing all keys from the process of trusting a device
    ///
    func trustDevice() async throws -> TrustDeviceResponse

    /// Creates and stores device keys making the device trusted, if should trust device.
    ///
    /// - Returns: A object containing all keys from the process of trusting a device
    ///
    func trustDeviceIfNeeded() async throws -> TrustDeviceResponse?

    ///  Stores device keys making the device trusted.
    ///
    /// - Parameter keys: A object containing all keys from the process of trusting a device done using the bw sdk
    ///
    func trustDeviceWithExistingKeys(keys: TrustDeviceResponse) async throws

    /// Removes device keys from the users account.
    ///
    func removeTrustedDevice() async throws

    /// Get value to decide if the device should be trusted.
    ///
    /// - Returns: Boolean value referring to if device should be trusted.
    ///
    func getShouldTrustDevice() async throws -> Bool

    /// Set value referring to if device should be trusted.
    ///
    /// - Parameter value: Boolean value referring to if device should be trusted.
    ///
    func setShouldTrustDevice(_ value: Bool) async throws

    /// Is the current device trusted.
    ///
    /// - Returns: Boolean value referring to if device is trusted.
    ///
    func isDeviceTrusted() async throws -> Bool
}

class DefaultTrustDeviceService: TrustDeviceService {
    /// The service used by the application to manage the app's ID.
    private let appIdService: AppIdService

    /// The API service used to make calls related to the auth process.
    private let authAPIService: AuthAPIService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The repository used to manages keychain items.
    private let keychainRepository: KeychainRepository

    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Initialization

    /// Creates a new `DefaultTrustDeviceService`.
    ///
    /// - Parameters:
    ///   - appIdService: The service used by the application to manage the app's ID.
    ///   - authAPIService: The API service used to make calls related to the auth process.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - keychainRepository: The repository used to manages keychain items.
    ///   - stateService: The object used by the application to retrieve information about this device.
    ///
    init(
        appIdService: AppIdService,
        authAPIService: AuthAPIService,
        clientService: ClientService,
        keychainRepository: KeychainRepository,
        stateService: StateService,
    ) {
        self.appIdService = appIdService
        self.authAPIService = authAPIService
        self.clientService = clientService
        self.keychainRepository = keychainRepository
        self.stateService = stateService
    }

    func getDeviceKey() async throws -> String? {
        let activeUserId = try await stateService.getActiveAccountId()
        do {
            return try await keychainRepository.getDeviceKey(userId: activeUserId)
        } catch {
            return nil
        }
    }

    func trustDevice() async throws -> BitwardenSdk.TrustDeviceResponse {
        let trustDeviceDetails = try await clientService.auth().trustDevice()
        return try await setDeviceAsTrusted(trustDeviceDetails)
    }

    func trustDeviceIfNeeded() async throws -> BitwardenSdk.TrustDeviceResponse? {
        if try await getShouldTrustDevice() == false {
            return nil
        }

        let response = try await trustDevice()
        try await setShouldTrustDevice(false)
        return response
    }

    func trustDeviceWithExistingKeys(keys: TrustDeviceResponse) async throws {
        _ = try await setDeviceAsTrusted(keys)
    }

    func removeTrustedDevice() async throws {
        let activeUserId = try await stateService.getActiveAccountId()
        try await keychainRepository.deleteDeviceKey(userId: activeUserId)
    }

    func getShouldTrustDevice() async throws -> Bool {
        let activeUserId = try await stateService.getActiveAccountId()
        return await stateService.getShouldTrustDevice(userId: activeUserId) ?? false
    }

    func setShouldTrustDevice(_ value: Bool) async throws {
        let activeUserId = try await stateService.getActiveAccountId()
        await stateService.setShouldTrustDevice(value, userId: activeUserId)
    }

    func isDeviceTrusted() async throws -> Bool {
        try await getDeviceKey() != nil
    }

    /// Updates server and local device keys making the device trusted.
    ///
    /// - Parameter trustDeviceDetails object containing all keys to trust a device
    /// - Returns: A object containing all keys from the process of trusting a device
    ///
    private func setDeviceAsTrusted(_ trustDeviceDetails: TrustDeviceResponse) async throws -> TrustDeviceResponse {
        let appId = await appIdService.getOrCreateAppId()
        let trustedDeviceKeysRequestModel = TrustedDeviceKeysRequestModel(
            encryptedPrivateKey: trustDeviceDetails.protectedDevicePrivateKey,
            encryptedPublicKey: trustDeviceDetails.protectedDevicePublicKey,
            encryptedUserKey: trustDeviceDetails.protectedUserKey,
        )

        try await authAPIService.updateTrustedDeviceKeys(
            deviceIdentifier: appId,
            model: trustedDeviceKeysRequestModel,
        )

        let activeUserId = try await stateService.getActiveAccountId()
        try await keychainRepository.setDeviceKey(trustDeviceDetails.deviceKey, userId: activeUserId)

        return trustDeviceDetails
    }
}
