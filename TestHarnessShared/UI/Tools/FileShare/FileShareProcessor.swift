import BitwardenKit
import Foundation
import UIKit

/// The processor for the file share test screen.
///
@available(iOS 16.0, *)
class FileShareProcessor: StateProcessor<FileShareState, FileShareAction, FileShareEffect> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    // MARK: Initialization

    /// Initialize a `FileShareProcessor`.
    ///
    /// - Parameter coordinator: The coordinator that handles navigation.
    ///
    init(coordinator: AnyCoordinator<RootRoute, Void>) {
        self.coordinator = coordinator
        super.init(state: FileShareState())
    }

    // MARK: Methods

    override func perform(_ effect: FileShareEffect) async {
        switch effect {
        case .viewAppeared:
            await prepareSampleFile()
            prepareShareableImage()
        }
    }

    override func receive(_ action: FileShareAction) {
        switch action {
        case let .textContentChanged(newValue):
            state.textContent = newValue
        }
    }

    // MARK: Private Methods

    /// Writes the sample PDF to the temporary directory and updates `state.shareableFileURL`.
    ///
    private func prepareSampleFile() async {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(FileShareState.sampleFileName)
        do {
            try FileShareState.helloWorldPdfData.write(to: fileURL)
            state.shareableFileURL = fileURL
        } catch {
            // Leave shareableFileURL as nil; the Share File button stays disabled.
        }
    }

    /// Generates a solid-color PNG image and stores its data in `state.shareableImageData`.
    ///
    private func prepareShareableImage() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
        state.shareableImageData = image.pngData()
    }
}
