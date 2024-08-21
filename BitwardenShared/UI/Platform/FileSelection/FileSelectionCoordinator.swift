@preconcurrency import PhotosUI
import UIKit

// MARK: - FileSelectionCoordinator

/// A coordinator that manages navigation for file selection routes.
///
@MainActor
class FileSelectionCoordinator: NSObject, Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasCameraService
        & HasErrorReporter

    // MARK: Properties

    /// The delegate for this coordinator.
    weak var delegate: FileSelectionDelegate?

    /// The services used by this processor.
    let services: Services

    /// The navigator that is used to present each of the flows within this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `FileSelectionCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for this coordinator.
    ///   - services: The services for this coordinator.
    ///   - stackNavigator: The navigator that is used to present each of the flows within this
    ///     coordinator. This navigator should be one already used in the coordinator that is
    ///     presenting this coordinator, since this navigator is purely used to present other flows
    ///     modally.
    ///
    init(
        delegate: FileSelectionDelegate,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.delegate = delegate
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: FileSelectionRoute, context: AnyObject?) {
        switch route {
        case .camera:
            showCamera()
        case .file:
            showFileBrowser()
        case .photo:
            showPhotoLibrary()
        }
    }

    func start() {}

    // MARK: Private Methods

    /// The provided image was selected from the photo library or the camera.
    ///
    /// - Parameters:
    ///   - image: The image that was selected.
    ///   - suggestedName: The name suggested by the system, if one was provided.
    ///   - typeIdentifiers: The list of type identifiers for the selected image.
    ///
    private func selected(image: UIImage, suggestedName: String?, typeIdentifiers: [String]) {
        var fileName = suggestedName ?? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMddHHmmss"
            return "photo_\(formatter.string(from: Date()))"
        }()
            .lowercased()

        let imageData: Data?
        let fileNameExtension: String
        if typeIdentifiers.contains(UTType.png.identifier) {
            imageData = image.pngData()
            fileNameExtension = ".png"
        } else {
            imageData = image.jpegData(compressionQuality: 1)
            fileNameExtension = ".jpg"
        }

        if !fileName.hasSuffix(fileNameExtension) {
            // PHPickerViewController may not provide the filename along with an extension, so
            // we need to provide one.
            fileName.append(fileNameExtension)
        }

        guard let imageData else { return }
        delegate?.fileSelectionCompleted(fileName: fileName, data: imageData)
    }

    /// Shows the camera screen.
    ///
    private func showCamera() {
        Task {
            if await services.cameraService.checkStatusOrRequestCameraAuthorization() == .authorized {
                let viewController = UIImagePickerController()
                viewController.sourceType = .camera
                viewController.allowsEditing = false
                viewController.delegate = self
                stackNavigator?.present(viewController)
            } else {
                // TODO: BIT-1466 Present an alert about camera permissions being needed.
            }
        }
    }

    /// Shows the file browser screen.
    ///
    private func showFileBrowser() {
        let viewController = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        viewController.allowsMultipleSelection = false
        viewController.shouldShowFileExtensions = true
        viewController.delegate = self
        stackNavigator?.present(viewController)
    }

    /// Shows the photo library screen.
    ///
    private func showPhotoLibrary() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let viewController = PHPickerViewController(configuration: configuration)
        viewController.delegate = self
        stackNavigator?.present(viewController)
    }
}

// MARK: - FileSelectionCoordinator:UIDocumentPickerDelegate

extension FileSelectionCoordinator: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: UI.animated)
        guard let url = urls.first else { return }

        let document = UIDocument(fileURL: url)
        let fileName = document.localizedName.nilIfEmpty
            ?? url.lastPathComponent.nilIfEmpty
            ?? Constants.unknownFileName

        do {
            let fileData = try Data(contentsOf: url)
            delegate?.fileSelectionCompleted(fileName: fileName, data: fileData)
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: UI.animated)
    }
}

// MARK: - FileSelectionCoordinator:PHPickerViewControllerDelegate

extension FileSelectionCoordinator: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: UI.animated)

        guard let result = results.first else { return }

        if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                if let error {
                    self?.services.errorReporter.log(error: error)
                    return
                }

                guard let image = image as? UIImage else { return }
                self?.selected(
                    image: image,
                    suggestedName: result.itemProvider.suggestedName,
                    typeIdentifiers: result.itemProvider.registeredTypeIdentifiers
                )
            }
        }
    }
}

// MARK: - FileSelectionCoordinator: UIImagePickerControllerDelegate

extension FileSelectionCoordinator: UIImagePickerControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss()

        guard let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage else { return }
        let typeIdentifiers = (info[.mediaType] as? String).map { [$0] } ?? []
        selected(image: image, suggestedName: nil, typeIdentifiers: typeIdentifiers)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss()
    }
}

// MARK: - FileSelectionCoordinator:UINavigationControllerDelegate

extension FileSelectionCoordinator: UINavigationControllerDelegate {}
