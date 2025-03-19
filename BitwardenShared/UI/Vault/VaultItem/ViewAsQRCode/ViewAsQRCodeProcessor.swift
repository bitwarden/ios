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
        case .closeTapped:
            coordinator.navigate(to: .dismiss())
        case let .qrCodeTypeChanged(type):
            changeQrType(type)
        case let .parameterChanged(fieldReference, index: index):
            updateField(fieldReference: fieldReference, index: index)
        }
    }

    // MARK: Private Methods

    func changeQrType(_ type: QRCodeType) {
        state.typeState = type.newState(cipher: cipher)
    }

    func updateField(fieldReference: CipherFieldType, index: Int) {
        state.typeState.parameters[index].selected = fieldReference
    }
}
