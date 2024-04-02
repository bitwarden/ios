import BitwardenSdk
import Combine
import Foundation
import OSLog

/// A protocol for an `ItemRepository` which manages acess to the data needed by the UI layer.
///
public protocol ItemRepository: AnyObject {
    // MARK: Data Methods

    func addItem(_ item: CipherView) async throws

    func deleteItem(_ id: String)

    func fetchItem(withId id: String) async throws -> CipherView?

    /// Regenerates the TOTP code for a given key.
    ///
    /// - Parameter key: The key for a TOTP code.
    /// - Returns: An updated LoginTOTPState.
    ///
    func refreshTOTPCode(for key: TOTPKeyModel) async throws -> LoginTOTPState

    /// Regenerates the TOTP codes for a list of Vault Items.
    ///
    /// - Parameter items: The list of items that need updated TOTP codes.
    /// - Returns: An updated list of items with new TOTP codes.
    ///
    func refreshTOTPCodes(for items: [VaultListItem]) async throws -> [VaultListItem]

    func updateItem(_ item: CipherView) async throws

    // MARK: Publishers

    func vaultListPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Never>>
}

class DefaultItemRepository {
    // MARK: Properties

    /// The client used by the application to handle vault encryption and decryption tasks.
    private let clientVault: ClientVaultService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used to get the present time.
    private let timeProvider: TimeProvider

    // MARK: Initialization

    /// Initialize a `DefaultItemRepository`.
    ///
    /// - Parameters:
    ///   - clientVault: The client used by the application to handle vault encryption and decryption tasks.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - timeProvider: The service used to get the present time.
    ///
    init(
        clientVault: ClientVaultService,
        errorReporter: ErrorReporter,
        timeProvider: TimeProvider
    ) {
        self.clientVault = clientVault
        self.errorReporter = errorReporter
        self.timeProvider = timeProvider
    }
}

extension DefaultItemRepository: ItemRepository {
    // MARK: Data Methods

    func addItem(_ item: BitwardenSdk.CipherView) async throws {}
    
    func deleteItem(_ id: String) {}
    
    func fetchItem(withId id: String) async throws -> BitwardenSdk.CipherView? {
        return nil
    }
    
    func refreshTOTPCode(for key: TOTPKeyModel) async throws -> LoginTOTPState {
        return .none
    }
    
    func refreshTOTPCodes(for items: [VaultListItem]) async throws -> [VaultListItem] {
        await items.asyncMap { item in
            guard case let .totp(name, model) = item.itemType,
                  let key = model.loginView.totp,
                  let code = try? await clientVault.generateTOTPCode(for: key, date: timeProvider.presentTime)
            else {
                errorReporter.log(error: TOTPServiceError
                    .unableToGenerateCode("Unable to refresh TOTP code for item: \(item.id)"))
                return item
            }
            var updatedModel = model
            updatedModel.totpCode = code
            return .init(
                id: item.id,
                itemType: .totp(name: name, totpModel: updatedModel)
            )
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    
    func updateItem(_ item: BitwardenSdk.CipherView) async throws {}
    
    // MARK: Publishers

    func vaultListPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[VaultListItem], Never>> {
        Just([
            VaultListItem(
                id: UUID().uuidString,
                itemType: .totp(
                    name: "Amazon",
                    totpModel: VaultListTOTP(
                        id: UUID().uuidString,
                        loginView: .init(
                            username: "Username",
                            password: "Password",
                            passwordRevisionDate: nil,
                            uris: nil,
                            totp: "amazon",
                            autofillOnPageLoad: false,
                            fido2Credentials: nil
                        ),
                        totpCode: TOTPCodeModel(
                            code: "123456",
                            codeGenerationDate: Date(),
                            period: 30
                        )
                    )
                )
            ),
            VaultListItem(
                id: UUID().uuidString,
                itemType: .totp(
                    name: "eBay",
                    totpModel: VaultListTOTP(
                        id: UUID().uuidString,
                        loginView: .init(
                            username: "Username",
                            password: "Password",
                            passwordRevisionDate: nil,
                            uris: nil,
                            totp: "ebay",
                            autofillOnPageLoad: false,
                            fido2Credentials: nil
                        ),
                        totpCode: TOTPCodeModel(
                            code: "123456",
                            codeGenerationDate: Date(),
                            period: 30
                        )
                    )
                )
            ),
        ])
        .eraseToAnyPublisher()
        .values
    }
}
