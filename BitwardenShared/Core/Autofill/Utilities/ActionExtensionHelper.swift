import Foundation
import OSLog

// MARK: - ActionExtensionHelper

/// A helper class for processing the input items of the action extension.
///
public class ActionExtensionHelper {
    // MARK: Properties

    /// Whether the app extension setup provider was included in the input items.
    public var isAppExtensionSetup: Bool {
        context.providerType == Constants.UTType.appExtensionSetup
    }

    // MARK: Private Properties

    /// An object containing the details of the processed items.
    private var context: ActionExtensionContext

    // MARK: Initialization

    /// Initialize an `ActionExtensionHelper`.
    ///
    public init() {
        context = ActionExtensionContext()
    }

    // MARK: Methods

    /// Processes the list of `NSExtensionItem`s from the extension context.
    ///
    /// - Parameter items: A list of `NSExtensionItem`s to process.
    ///
    public func processInputItems(_ items: [NSExtensionItem]) {
        for item in items {
            Logger.appExtension.debug("Input item: \(item, privacy: .public)")

            guard let attachments = item.attachments else { continue }

            var processed = false
            for provider in attachments {
                Logger.appExtension.debug("Input provider: \(provider, privacy: .public)")

                if processExtensionSetupProvider(provider) {
                    processed = true
                    break
                }
            }

            if processed {
                break
            }
        }
    }

    // MARK: Private

    /// Processes a potential `NSItemProvider` to determine if it conforms to the app extension
    /// setup type.
    ///
    /// - Parameter itemProvider: The `NSItemProvider` to process.
    /// - Returns: Whether the item provider conforms to the app extension setup type.
    ///
    private func processExtensionSetupProvider(_ itemProvider: NSItemProvider) -> Bool {
        guard itemProvider.hasItemConformingToTypeIdentifier(Constants.UTType.appExtensionSetup) else {
            return false
        }
        context.providerType = Constants.UTType.appExtensionSetup
        Logger.appExtension.debug("Processed extension setup provider")
        return true
    }
}
