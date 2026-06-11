import Foundation
import UIKit

/// The state for the file share test screen.
///
struct FileShareState: Equatable {
    // MARK: Static Properties

    /// The raw bytes written to the sample PDF file.
    static let helloWorldPdfData: Data = {
        let textToDraw = "Hello World"
        let bounds = CGRect(x: 0, y: 0, width: 600, height: 800)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let font = UIFont.systemFont(ofSize: 24)
        return renderer.pdfData { context in
            context.beginPage()
            textToDraw.draw(
                at: CGPoint(x: 100, y: 100),
                withAttributes: [.font: font],
            )
        }
    }()

    /// The name of the sample PDF file written to the temporary directory.
    static let sampleFileName = "bitwarden-sample.pdf"

    /// The display name for the generated PNG image shared via the iOS share sheet.
    static let sampleImageName = "bitwarden-sample.png"

    // MARK: Properties

    /// The URL of the sample PDF file in the temporary directory, once available.
    var shareableFileURL: URL?

    /// The PNG data for the generated sample image, once available.
    var shareableImageData: Data?

    /// The text content to share via the iOS share sheet.
    var textContent: String = "Sample text to share via Bitwarden Send."

    /// The title of the screen.
    var title: String = Localizations.fileShare
}
