import BitwardenKit
import BitwardenSdk
import Foundation

/// Protocol defining the functionality of a TOTP (Time-based One-Time Password) service.
protocol TOTPService {
    /// Attempts to copy the totp to the clipboard if there is one to copy and the action is enabled.
    /// - Parameter cipher: `CipherView` that contains totp information and permissions.
    func copyTotpIfPossible(cipher: CipherView) async throws

    /// Retrieves the TOTP configuration for a given key.
    ///
    /// - Parameter key: A string representing the TOTP key.
    /// - Throws: `TOTPKeyError.invalidKeyFormat` if the key format is invalid.
    /// - Returns: A `TOTPKeyModel` containing the configuration details.
    func getTOTPConfiguration(key: String?) throws -> TOTPKeyModel

    /// Returns whether the active account is authorized to use TOTP for the given cipher.
    /// - Parameter cipher: The cipher to check authorization for.
    /// - Returns: `true` if the account has premium or the cipher's organization has TOTP enabled.
    func isTotpAuthorized(for cipher: CipherView) async -> Bool
}

/// Default implementation of the `TOTPService`.
struct DefaultTOTPService: TOTPService {
    // MARK: Private properties

    /// The service used by the application to handle encryption and decryption tasks.
    private let clientService: ClientService
    /// The service used by the application for sharing data with other apps.
    private let pasteboardService: PasteboardService
    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Init

    /// Initializes a `DefaultTOTPService`.
    /// - Parameters:
    ///   - clientService: The service used by the application to handle encryption and decryption tasks.
    ///   - pasteboardService: The service used by the application for sharing data with other apps.
    ///   - stateService: The service used by the application to manage account state.
    init(
        clientService: ClientService,
        pasteboardService: PasteboardService,
        stateService: StateService,
    ) {
        self.clientService = clientService
        self.pasteboardService = pasteboardService
        self.stateService = stateService
    }

    // MARK: Methods

    func copyTotpIfPossible(cipher: CipherView) async throws {
        guard let totp = cipher.login?.totp else {
            return
        }

        let disableAutoTotpCopy = try await stateService.getDisableAutoTotpCopy()
        guard !disableAutoTotpCopy else {
            return
        }

        guard await isTotpAuthorized(for: cipher) else {
            return
        }

        let codeModel = try await clientService.vault().generateTOTPCode(for: totp, date: nil)
        pasteboardService.copy(codeModel.code)
    }

    func getTOTPConfiguration(key: String?) throws -> TOTPKeyModel {
        guard let key else {
            throw TOTPKeyError.invalidKeyFormat
        }

        return TOTPKeyModel(authenticatorKey: key)
    }

    func isTotpAuthorized(for cipher: CipherView) async -> Bool {
        let accountHasPremium = await stateService.doesActiveAccountHavePremium()
        return cipher.organizationUseTotp || accountHasPremium
    }
}
