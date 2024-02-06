import Foundation
import OSLog
import UIKit
import UniformTypeIdentifiers

// MARK: - ShareExtensionHelper

/// A helper class for processing the input items of the action extension.
///
@MainActor
public class ShareExtensionHelper {
    // MARK: Initialization

    /// Creates a new `ShareExtensionHelper`.
    ///
    public init() {}

    // MARK: Methods

    /// Processes the list of `NSExtensionItem`s from the extension context.
    ///
    /// - Parameter items: A list of `NSExtensionItem`s to process.
    /// - Returns: An `AddSendContentType` value, if one could be decoded from the items.
    ///
    public func processInputItems(_ items: [NSExtensionItem]) async -> AddSendContentType? {
        guard let itemProvider = items.first?.attachments?.first else { return nil }
        Logger.appExtension.debug("Item Provider: \(itemProvider, privacy: .public)")
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
           let text = try? await itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier),
           let text = text as? String {
            return .text(text)
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.data.identifier),
                  let data = try? await itemProvider.loadItem(forTypeIdentifier: UTType.data.identifier) {
            if let url = data as? URL {
                let fileName = url.lastPathComponent
                if let imageData = try? Data(contentsOf: url) {
                    return .file(fileName: fileName, fileData: imageData)
                }
            } else if let image = data as? UIImage {
                if let imageData = image.pngData() {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyyMMddHHmmss"
                    let fileName = "image_\(formatter.string(from: Date())).png"
                    return .file(fileName: fileName, fileData: imageData)
                }
            }

            return nil
        }

        return nil
    }
}
