import BitwardenSdk
import Foundation
import OSLog

// MARK: - ViewAsQRCodeProcessor

/// The processor used to manage state and handle actions for the View as QR Code screen.
///
final class ViewAsQRCodeProcessor: StateProcessor<
    ViewAsQRCodeState,
    ViewAsQRCodeAction,
    ViewAsQRCodeEffect
> {
    // MARK: Types

    typealias Services = HasErrorReporter

    // MARK: Private Properties

    /// The cipher to generate a QR card for.
    private let cipher: CipherView

    /// The `Coordinator` that handles navigation; this is typically a `VaultItemCoordinator`.
    private let coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `ViewAsQRCodeProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by the processor.
    ///   - cipher: The cipher to generate a QR code for.
    ///   - state: The initial state for the processor.
    ///
    init(
        cipher: CipherView,
        coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>,
        services: Services,
        state: ViewAsQRCodeState
    ) {
        self.cipher = cipher
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: ViewAsQRCodeEffect) async {
        switch effect {
        case .appeared:
            break
        }
    }

    override func receive(_ action: ViewAsQRCodeAction) {
        switch action {
        case let .qrCodeTypeChanged(type):
            break
        case let .additionalFieldChanged(fieldReference, index: index):
            foobar(fieldReference: fieldReference, index: index)
        default:
            break
        }
    }

    // MARK: Private Methods

    func foobar(fieldReference: CipherFieldType, index: Int) {
        state.selectedFields[index] = fieldReference
    }

//    func foobar(fieldReference: QRCodeFieldReference, index: Int) {
//        state.additionalProperties[index].selected = fieldReference
//        let ssid = valueForField(cipher: cipher, field: state.additionalProperties[0].selected.cipherField) ?? "Error"
//        let password = valueForField(cipher: cipher, field: state.additionalProperties[1].selected.cipherField) ?? "Error"
//        state.string = "WIFI:T:WPA;S:\(ssid);P:\(password);;"
//    }

    func valueForField(cipher: CipherView, field: CipherFieldType) -> String? {
        switch field {
        case .none:
            return nil
        case .username:
            return cipher.login?.username
        case .password:
            return cipher.login?.password
        case .notes:
            return cipher.notes
        case let .uri(index: uriIndex):
            return cipher.login?.uris?[uriIndex].uri
        case let .custom(name: name):
            return cipher.customFields.first(where: {$0.name == name})?.value
        }
    }
}
