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

    @Published var ciphers: [CipherView] = [
        CipherView(
            id: UUID().uuidString,
            organizationId: nil,
            folderId: nil,
            collectionIds: [],
            key: nil,
            name: "Amazon",
            notes: nil,
            type: .login,
            login: .init(
                username: "amazon@example.com",
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: "amazon",
                autofillOnPageLoad: nil,
                fido2Credentials: nil
            ),
            identity: nil,
            card: nil,
            secureNote: nil,
            favorite: false,
            reprompt: .none,
            organizationUseTotp: false,
            edit: false,
            viewPassword: false,
            localData: nil,
            attachments: nil,
            fields: nil,
            passwordHistory: nil,
            creationDate: .now,
            deletedDate: nil,
            revisionDate: .now
        ),
    ]

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

    func addItem(_ item: BitwardenSdk.CipherView) async throws {
        ciphers.append(item)
    }

    func deleteItem(_ id: String) {}

    func fetchItem(withId id: String) async throws -> BitwardenSdk.CipherView? { nil }

    func refreshTOTPCode(for key: TOTPKeyModel) async throws -> LoginTOTPState { .none }

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
        ciphers.publisher
//            .asyncMap {
//                $0.compactMap({
//                    totpItem(for: $0)
//                })
//            }
//            .asyncMap({
//                $0.map({
//                    VaultListItem(cipherView: $0)
//                })
//            })
            .asyncCompactMap({ await self.totpItem(for: $0) })
            .collect()
//        await Just(ciphers.asyncMap({ await self.totpItem(for: $0)! }))
        .eraseToAnyPublisher()
        .values
    }

    /// A transform to convert a `CipherView` into a TOTP `VaultListItem`.
    ///
    /// - Parameter cipherView: The cipher view that may have a TOTP key.
    /// - Returns: A `VaultListItem` if the CipherView supports TOTP.
    ///
    private func totpItem(for cipherView: CipherView) async -> VaultListItem? {
        guard let id = cipherView.id,
              let login = cipherView.login,
              let key = login.totp else {
            return nil
        }
        guard let code = try? await clientVault.generateTOTPCode(
            for: key,
            date: timeProvider.presentTime
        ) else {
            errorReporter.log(
                error: TOTPServiceError
                    .unableToGenerateCode("Unable to create TOTP code for key \(key) for cipher id \(id)")
            )
            return nil
        }

        let listModel = VaultListTOTP(
            id: id,
            loginView: login,
            totpCode: code
        )
        return VaultListItem(
            id: id,
            itemType: .totp(
                name: cipherView.name,
                totpModel: listModel
            )
        )
    }
}
