import Photos
import PhotosUI
import SwiftUI

// MARK: - SendCoordinator

/// A coordinator that manages navigation in the send tab.
///
final class SendCoordinator: NSObject, Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasSendRepository

    // MARK: Private Properties

    /// The current file selection delegate.
    private weak var fileSelectionDelegate: FileSelectionDelegate?

    // MARK: Properties

    /// The services used by this processor.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    let stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `SendCoordinator`.
    ///
    /// - Parameters:
    ///   - services: The services used by this processor.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: SendRoute, context: AnyObject?) {
        switch route {
        case .addItem:
            showAddItem()
        case .camera:
            guard let delegate = context as? FileSelectionDelegate else { return }
            fileSelectionDelegate = delegate
            showCamera()
        case .dismiss:
            stackNavigator.dismiss()
        case .fileBrowser:
            guard let delegate = context as? FileSelectionDelegate else { return }
            fileSelectionDelegate = delegate
            showFileBrowser()
        case .list:
            showList()
        case .photoLibrary:
            guard let delegate = context as? FileSelectionDelegate else { return }
            fileSelectionDelegate = delegate
            showPhotoLibrary()
        }
    }

    func start() {
        navigate(to: .list)
    }

    // MARK: Private methods

    /// The provided image was selected from the photo library or the camera.
    ///
    /// - Parameters:
    ///   - image: The image that was selected.
    ///   - suggestedName: The name suggested by the system, if one was provided.
    ///
    private func selected(image: UIImage, suggestedName: String?) {
        let fileName = suggestedName ?? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMddHHmmss"
            return "photo_\(formatter.string(from: Date())).jpg"
        }()
            .lowercased()

        let imageData: Data?
        if fileName.hasSuffix("jpg") || fileName.hasSuffix("jpeg") {
            imageData = image.jpegData(compressionQuality: 1)
        } else {
            imageData = image.pngData()
        }
        guard let imageData else { return }
        fileSelectionDelegate?.fileSelectionCompleted(fileName: fileName, data: imageData)
    }

    /// Shows the add item screen.
    ///
    private func showAddItem() {
        Task {
            let hasPremium = try? await services.sendRepository.doesActiveAccountHavePremium()
            let state = AddEditSendItemState(
                hasPremium: hasPremium ?? false
            )
            let processor = AddEditSendItemProcessor(
                coordinator: self,
                state: state
            )
            let view = AddEditSendItemView(store: Store(processor: processor))
            let viewController = UIHostingController(rootView: view)
            let navigationController = UINavigationController(rootViewController: viewController)
            stackNavigator.present(navigationController)
        }
    }

    /// Shows the camera screen.
    ///
    private func showCamera() {
        let viewController = UIImagePickerController()
        viewController.sourceType = .camera
        viewController.allowsEditing = false
        viewController.delegate = self
        stackNavigator.present(viewController)
    }

    /// Shows the file browser screen.
    ///
    private func showFileBrowser() {
        let viewController = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        viewController.allowsMultipleSelection = false
        viewController.delegate = self
        viewController.shouldShowFileExtensions = true
        stackNavigator.present(viewController)
    }

    /// Shows the list of sends.
    ///
    private func showList() {
        let processor = SendListProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: SendListState()
        )
        let store = Store(processor: processor)
        let view = SendListView(store: store)
        stackNavigator.replace(view)
    }

    /// Shows the photo library screen.
    ///
    private func showPhotoLibrary() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let viewController = PHPickerViewController(configuration: configuration)
        viewController.delegate = self
        stackNavigator.present(viewController)
    }
}

extension SendCoordinator: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: UI.animated)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: UI.animated)
        guard let url = urls.first else { return }

        let document = UIDocument(fileURL: url)
        let fileName = document.localizedName.nilIfEmpty
            ?? url.lastPathComponent.nilIfEmpty
            ?? "unknown_file_name"

        guard let fileData = FileManager().contents(atPath: url.absoluteString)
            ?? (try? Data(contentsOf: url))
        else { return }

        print("success!")
        fileSelectionDelegate?.fileSelectionCompleted(fileName: fileName, data: fileData)
    }
}

extension SendCoordinator: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: UI.animated)

        guard let result = results.first else { return }

        if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
            result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                if let error {
                    print(error)
                    // TODO: log error
                }

                guard let image = image as? UIImage else { return }
                self.selected(image: image, suggestedName: result.itemProvider.suggestedName)
            }
        }
    }
}

extension SendCoordinator: UIImagePickerControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss()

        guard let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage else { return }
        selected(image: image, suggestedName: nil)
    }
}

extension SendCoordinator: UINavigationControllerDelegate {}
