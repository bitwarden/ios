import BitwardenKit
import BitwardenSdk
import SwiftUI

// swiftlint:disable file_length

// MARK: - VaultItemCoordinator

/// A coordinator that manages navigation for displaying, editing, and adding individual vault items.
///
class VaultItemCoordinator: NSObject, Coordinator, HasStackNavigator { // swiftlint:disable:this type_body_length
    // MARK: Types

    typealias Module = AddEditFolderModule
        & FileSelectionModule
        & GeneratorModule
        & NavigatorBuilderModule
        & PasswordHistoryModule
        & VaultItemModule

    typealias Services = AuthenticatorKeyCaptureCoordinator.Services
        & GeneratorCoordinator.Services
        & HasAPIService
        & HasAuthRepository
        & HasConfigService
        & HasEnvironmentService
        & HasErrorAlertServices.ErrorAlertServices
        & HasEventService
        & HasFido2UserInterfaceHelper
        & HasRehydrationHelper
        & HasSettingsRepository
        & HasStateService
        & HasTOTPService
        & HasTimeProvider
        & HasVaultRepository

    // MARK: - Private Properties

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// The most recent coordinator used to navigate to a `FileSelectionRoute`. Used to keep the
    /// coordinator in memory.
    private var fileSelectionCoordinator: AnyCoordinator<FileSelectionRoute, Void>?

    /// The module used by this coordinator to create child coordinators.
    private let module: Module

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `VaultCoordinator`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - module: The module used by this coordinator to create child coordinators.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        appExtensionDelegate: AppExtensionDelegate?,
        module: Module,
        services: Services,
        stackNavigator: StackNavigator,
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        self.module = module
        self.services = services
        self.stackNavigator = stackNavigator
    }

    func handleEvent(_ event: VaultItemEvent, context: AnyObject?) async {
        switch event {
        case .showScanCode:
            guard let delegate = context as? AuthenticatorKeyCaptureDelegate else { return }
            await showCamera(delegate: delegate)
        }
    }

    func navigate(to route: VaultItemRoute, context: AnyObject?) { // swiftlint:disable:this function_body_length
        switch route {
        case .addFolder:
            showAddFolder(delegate: context as? AddEditFolderDelegate)
        case let .addItem(
            group,
            hasPremium,
            newCipherOptions,
            organizationId,
            type,
        ):
            showAddItem(
                for: group,
                hasPremium: hasPremium,
                newCipherOptions: newCipherOptions,
                organizationId: organizationId,
                type: type,
                delegate: context as? CipherItemOperationDelegate,
            )
        case let .attachments(cipher):
            showAttachments(for: cipher)
        case let .cloneItem(cipher, hasPremium):
            showCloneItem(for: cipher, delegate: context as? CipherItemOperationDelegate, hasPremium: hasPremium)
        case let .dismiss(onDismiss):
            stackNavigator?.dismiss(animated: true, completion: {
                onDismiss?.action()
            })
        case let .editCollections(cipher):
            showEditCollections(cipher: cipher, delegate: context as? EditCollectionsProcessorDelegate)
        case let .editItem(cipher, hasPremium):
            showEditItem(for: cipher, hasPremium: hasPremium, delegate: context as? CipherItemOperationDelegate)
        case let .fileSelection(route):
            guard let delegate = context as? FileSelectionDelegate else { return }
            showFileSelection(route: route, delegate: delegate)
        case let .generator(type, emailWebsite):
            guard let delegate = context as? GeneratorCoordinatorDelegate else { return }
            showGenerator(for: type, emailWebsite: emailWebsite, delegate: delegate)
        case let .migrateToMyItems(organizationId):
            showMigrateToMyItems(
                organizationId: organizationId,
                delegate: context as? MigrateToMyItemsProcessorDelegate,
            )
        case let .moveToOrganization(cipher):
            showMoveToOrganization(cipher: cipher, delegate: context as? MoveToOrganizationProcessorDelegate)
        case let .passwordHistory(passwordHistory):
            showPasswordHistory(passwordHistory)
        case let .saveFile(temporaryUrl):
            showSaveFile(temporaryUrl)
        case .setupTotpManual:
            guard let delegate = context as? AuthenticatorKeyCaptureDelegate else { return }
            showManualTotp(delegate: delegate)
        case let .viewItem(id):
            showViewItem(id: id, delegate: context as? CipherItemOperationDelegate)
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Present a child `VaultItemCoordinator` on top of the existing coordinator.
    ///
    /// Presenting a view on top of an already presented view within the same coordinator causes
    /// problems when dismissing only the top view. So instead, present a new coordinator and
    /// show the view to navigate to within that coordinator's navigator.
    ///
    /// - Parameter route: The route to navigate to in the presented coordinator.
    ///
    private func presentChildVaultItemCoordinator(route: VaultItemRoute, context: AnyObject?) {
        let navigationController = module.makeNavigationController()
        let coordinator = module.makeVaultItemCoordinator(stackNavigator: navigationController)
        coordinator.navigate(to: route, context: context)
        coordinator.start()
        stackNavigator?.present(navigationController)
    }

    /// Shows the add folder screen.
    ///
    /// - Parameter delegate: A `AddEditFolderDelegate` that is notified when the user makes a
    ///     change to folders.
    ///
    private func showAddFolder(delegate: AddEditFolderDelegate?) {
        let navigationController = module.makeNavigationController()
        let coordinator = module.makeAddEditFolderCoordinator(stackNavigator: navigationController)
        coordinator.start()
        coordinator.navigate(to: .addEditFolder(folder: nil), context: delegate)

        stackNavigator?.present(navigationController)
    }

    /// Shows the add item screen.
    ///
    /// - Parameters:
    ///   - group: An optional `VaultListGroup` to initialize this view with.
    ///   - hasPremium: Whether the user has premium,
    ///   - newCipherOptions: Options that can be used to pre-populate the add item screen.
    ///   - organizationId: The organization id in case an organization was selected in the vault filter.
    ///   - type: The type of item to add.
    ///   - delegate: A `CipherItemOperationDelegate` delegate that is notified when specific circumstances
    ///     in the add/edit/delete item view have occurred.
    ///
    private func showAddItem( // swiftlint:disable:this function_parameter_count
        for group: VaultListGroup?,
        hasPremium: Bool,
        newCipherOptions: NewCipherOptions?,
        organizationId: String?,
        type: CipherType,
        delegate: CipherItemOperationDelegate?,
    ) {
        let state = CipherItemState(
            addItem: type,
            collectionIds: group?.collectionId.flatMap { [$0] } ?? [],
            folderId: group?.folderId,
            hasPremium: hasPremium,
            name: newCipherOptions?.name,
            organizationId: organizationId ?? group?.organizationId,
            password: newCipherOptions?.password,
            totpKeyString: newCipherOptions?.totpKey,
            uri: newCipherOptions?.uri,
            username: newCipherOptions?.username,
        )
        let processor = AddEditItemProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: state,
            vaultItemActionHelper: DefaultVaultItemActionHelper(
                coordinator: asAnyCoordinator(),
                services: services,
            ),
        )
        let store = Store(processor: processor)
        let view = AddEditItemView(store: store)
        stackNavigator?.replace(view)
    }

    /// Shows the attachments screen.
    ///
    /// - Parameter cipher: The cipher to show the attachments for.
    ///
    private func showAttachments(for cipher: CipherView) {
        let processor = AttachmentsProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: AttachmentsState(cipher: cipher),
        )
        stackNavigator?.present(AttachmentsView(store: Store(processor: processor)))
    }

    /// Shows the totp camera setup screen.
    ///
    private func showCamera(delegate: AuthenticatorKeyCaptureDelegate) async {
        let navigationController = module.makeNavigationController()
        let coordinator = AuthenticatorKeyCaptureCoordinator(
            appExtensionDelegate: appExtensionDelegate,
            delegate: delegate,
            services: services,
            stackNavigator: navigationController,
        )
        coordinator.start()

        await coordinator.handleEvent(.showScanCode, context: self)
        stackNavigator?.present(navigationController, overFullscreen: true)
    }

    /// Shows the clone item screen.
    ///
    /// - Parameters:
    ///   - cipherView: A `CipherView` to initialize this view with.
    ///   - delegate: A `CipherItemOperationDelegate` delegate that is notified when specific circumstances
    ///     in the add/edit/delete item view have occurred.
    ///   - hasPremium: Whether the user has premium.
    ///
    private func showCloneItem(
        for cipherView: CipherView,
        delegate: CipherItemOperationDelegate?,
        hasPremium: Bool,
    ) {
        guard let stackNavigator else { return }
        let state = CipherItemState(
            cloneItem: cipherView,
            hasPremium: hasPremium,
        )
        if stackNavigator.isEmpty {
            let processor = AddEditItemProcessor(
                appExtensionDelegate: appExtensionDelegate,
                coordinator: asAnyCoordinator(),
                delegate: delegate,
                services: services,
                state: state,
                vaultItemActionHelper: DefaultVaultItemActionHelper(
                    coordinator: asAnyCoordinator(),
                    services: services,
                ),
            )
            let store = Store(processor: processor)
            let view = AddEditItemView(store: store)
            stackNavigator.replace(view)
        } else {
            presentChildVaultItemCoordinator(
                route: .cloneItem(cipher: cipherView, hasPremium: hasPremium),
                context: delegate,
            )
        }
    }

    /// Shows the move to organization screen.
    ///
    private func showEditCollections(cipher: CipherView, delegate: EditCollectionsProcessorDelegate?) {
        let processor = EditCollectionsProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: EditCollectionsState(cipher: cipher),
        )
        stackNavigator?.present(EditCollectionsView(store: Store(processor: processor)))
    }

    /// Shows the edit item screen.
    /// .
    /// - Parameters:
    ///   - cipherView: The `CipherView` to edit.
    ///   - hasPremium: Whether the user has premium.
    ///   - delegate: The delegate for the view.
    ///
    private func showEditItem(for cipherView: CipherView, hasPremium: Bool, delegate: CipherItemOperationDelegate?) {
        guard let stackNavigator else { return }
        if stackNavigator.isEmpty {
            guard let state = CipherItemState(
                existing: cipherView,
                hasPremium: hasPremium,
            ) else { return }

            let processor = AddEditItemProcessor(
                appExtensionDelegate: appExtensionDelegate,
                coordinator: asAnyCoordinator(),
                delegate: delegate,
                services: services,
                state: state,
                vaultItemActionHelper: DefaultVaultItemActionHelper(
                    coordinator: asAnyCoordinator(),
                    services: services,
                ),
            )
            let store = Store(processor: processor)
            let view = AddEditItemView(store: store)
            stackNavigator.replace(view)
        } else {
            presentChildVaultItemCoordinator(route: .editItem(cipherView, hasPremium), context: delegate)
        }
    }

    /// Navigates to the specified `FileSelectionRoute`.
    ///
    /// - Parameters:
    ///   - route: The route to navigate to.
    ///   - delegate: The `FileSelectionDelegate` for this navigation.
    ///
    private func showFileSelection(
        route: FileSelectionRoute,
        delegate: FileSelectionDelegate,
    ) {
        guard let stackNavigator else { return }
        let coordinator = module.makeFileSelectionCoordinator(
            delegate: delegate,
            stackNavigator: stackNavigator,
        )
        coordinator.start()
        coordinator.navigate(to: route)
        fileSelectionCoordinator = coordinator
    }

    /// Shows the generator screen for the the specified type.
    ///
    /// - Parameters:
    ///   - type: The type to generate.
    ///   - emailWebsite: An optional website host used to generate usernames.
    ///   - delegate: The delegate for this generator flow.
    ///
    private func showGenerator(
        for type: GeneratorType,
        emailWebsite: String?,
        delegate: GeneratorCoordinatorDelegate,
    ) {
        let navigationController = module.makeNavigationController()
        if type != .username {
            // Username doesn't show the segmented control so the divider should show. Otherwise,
            // remove it to make the segmented control appear to be part of the navigation controller.
            navigationController.removeHairlineDivider()
        }
        let coordinator = module.makeGeneratorCoordinator(
            delegate: delegate,
            stackNavigator: navigationController,
        ).asAnyCoordinator()
        coordinator.start()
        coordinator.navigate(to: .generator(staticType: type, emailWebsite: emailWebsite))
        stackNavigator?.present(navigationController)
    }

    /// Shows the totp manual setup screen.
    ///
    private func showManualTotp(delegate: AuthenticatorKeyCaptureDelegate) {
        let navigationController = module.makeNavigationController()
        let coordinator = AuthenticatorKeyCaptureCoordinator(
            appExtensionDelegate: appExtensionDelegate,
            delegate: delegate,
            services: services,
            stackNavigator: navigationController,
        ).asAnyCoordinator()
        coordinator.start()
        coordinator.navigate(to: .manualKeyEntry, context: nil)
        stackNavigator?.present(navigationController)
    }

    /// Shows the migrate to my items screen.
    ///
    /// - Parameters:
    ///   - organizationId: The organization ID that requires the vault migration.
    ///   - delegate: The delegate to notify of events.
    ///
    private func showMigrateToMyItems(
        organizationId: String,
        delegate: MigrateToMyItemsProcessorDelegate?,
    ) {
        let processor = MigrateToMyItemsProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: MigrateToMyItemsState(organizationId: organizationId),
        )
        let view = MigrateToMyItemsView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }

    /// Shows the move to organization screen.
    ///
    private func showMoveToOrganization(cipher: CipherView, delegate: MoveToOrganizationProcessorDelegate?) {
        let processor = MoveToOrganizationProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: MoveToOrganizationState(cipher: cipher),
        )
        stackNavigator?.present(MoveToOrganizationView(store: Store(processor: processor)))
    }

    /// A route to view the password history view.
    ///
    /// - Parameter passwordHistory: The password history to view.
    ///
    private func showPasswordHistory(_ passwordHistory: [PasswordHistoryView]) {
        let navigationController = module.makeNavigationController()
        let coordinator = module.makePasswordHistoryCoordinator(stackNavigator: navigationController)
        coordinator.start()
        coordinator.navigate(to: .passwordHistoryList(.item(passwordHistory)))
        stackNavigator?.present(navigationController)
    }

    /// Present the `UIDocumentPickerViewController` that allows users to save the newly downloaded file.
    ///
    /// - Parameter temporaryUrl: The temporary url where the file is currently stored.
    ///
    private func showSaveFile(_ temporaryUrl: URL) {
        let documentController = UIDocumentPickerViewController(forExporting: [temporaryUrl])
        stackNavigator?.present(documentController)
    }

    /// Shows the view item screen.
    ///
    /// - Parameters:
    ///   - id: The id of the item to show.
    ///   - delegate: The delegate.
    ///
    private func showViewItem(id: String, delegate: CipherItemOperationDelegate?) {
        let processor = ViewItemProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            itemId: id,
            services: services,
            state: ViewItemState(),
            vaultItemActionHelper: DefaultVaultItemActionHelper(
                coordinator: asAnyCoordinator(),
                services: services,
            ),
        )
        let store = Store(processor: processor)
        let view = ViewItemView(
            store: store,
            timeProvider: services.timeProvider,
        )
        stackNavigator?.replace(view)
    }
}

// MARK: - HasErrorAlertServices

extension VaultItemCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
