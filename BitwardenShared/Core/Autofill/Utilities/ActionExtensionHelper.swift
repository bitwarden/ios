import Foundation
import OSLog
import UniformTypeIdentifiers

// MARK: - ActionExtensionHelper

/// A helper class for processing the input items of the action extension.
///
public class ActionExtensionHelper {
    // MARK: Properties

    /// Whether the app extension setup provider was included in the input items.
    public var isAppExtensionSetup: Bool {
        context.providerType == Constants.UTType.appExtensionSetup
    }

    /// The URL of the page or app to determine matching ciphers.
    public var uri: String? {
        context.urlString
    }

    // MARK: Private Properties

    /// An object containing the details of the processed items.
    private(set) var context: ActionExtensionContext

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

                if processWebUrlProvider(provider) ||
                    processExtensionSetupProvider(provider) {
                    processed = true
                    break
                }
            }

            if processed {
                break
            }
        }
    }

    /// Returns a dictionary of the item data used to complete the extension request.
    ///
    /// - Parameters:
    ///   - username: The username of cipher that the user selected to autofill.
    ///   - password: The password of cipher that the user selected to autofill.
    /// - Returns: A dictionary of the item data used to complete the extension request.
    ///
    public func itemDataToCompleteRequest(username: String, password: String) -> [String: Any] {
        var itemData = [String: Any]()

        if context.providerType == UTType.propertyList.identifier {
            let fillScript = FillScript(
                pageDetails: context.pageDetails,
                fillUsername: username,
                fillPassword: password,
                fillFields: [] // TODO
            )
            do {
                let scriptJsonData = try JSONEncoder().encode(fillScript)
                if let scriptJson = String(data: scriptJsonData, encoding: .utf8) {
                    let scriptDictionary = [Constants.appExtensionWebViewPageFillScript: scriptJson]
                    itemData[NSExtensionJavaScriptFinalizeArgumentKey] = scriptDictionary
                }
            } catch {
                Logger.application.error("Error encoding fill script. Error: \(error, privacy: .public)")
            }
        }

        return itemData
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
        defer { context.didFinishLoadingItem = true }
        context.providerType = Constants.UTType.appExtensionSetup
        Logger.appExtension.debug("Processed extension setup provider")
        return true
    }

    /// Processes a `NSItemProvider` to determine if it conforms to the specified type, loads the
    /// item's data and calls either the `dictionaryHandler` or `urlHandler` based on the type of
    /// the loaded item.
    ///
    /// - Parameters:
    ///   - itemProvider: The `NSItemProvider` to process.
    ///   - type: The type identifier to check that the item provider conforms to.
    ///   - dictionaryHandler: A closure to call if the item is a dictionary.
    ///   - urlHandler: A closure to call if the item is a URL.
    /// - Returns: Whether the item provider conforms to the property list type.
    ///
    private func processItemProvider(
        _ itemProvider: NSItemProvider,
        type: String,
        dictionaryHandler: (([String: Any]) -> Void)? = nil,
        urlHandler: ((URL) -> Void)? = nil
    ) -> Bool {
        guard itemProvider.hasItemConformingToTypeIdentifier(type) else { return false }
        itemProvider.loadItem(forTypeIdentifier: type) { item, error in
            guard let item else {
                Logger.appExtension.error("Unable to load item for type \(type). Error: \(String(describing: error))")
                return
            }

            self.context.providerType = type

            Logger.appExtension.debug("Loaded item for type \(type). Item: \(String(describing: item), privacy: .public)")

            switch item {
            case let item as URL:
                urlHandler?(item)
            case let item as [String: Any]:
                dictionaryHandler?(item)
            default:
                break
            }
        }

        return true
    }

    /// Processes a potential `NSItemProvider` to determine if it conforms to a property list type
    /// to autofill credentials on a web page
    ///
    /// - Parameter itemProvider: The `NSItemProvider` to process.
    /// - Returns: Whether the item provider conforms to the property list type.
    ///
    private func processWebUrlProvider(_ itemProvider: NSItemProvider) -> Bool {
        processItemProvider(itemProvider, type: UTType.propertyList.identifier) { (dictionary: [String: Any]) in
            defer { self.context.didFinishLoadingItem = true }
            guard let result = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: String]
            else { return }

            self.context.urlString = result[Constants.appExtensionUrlStringKey]
            if let json = result[Constants.appExtensionWebViewPageDetails] {
                Logger.appExtension.debug("Processing web URL provider. JSON: \(json, privacy: .public)")
                do {
                    let pageDetails = try JSONDecoder().decode(PageDetails.self, from: Data(json.utf8))
                    Logger.appExtension
                        .debug("Processing web URL provider. Page details: \(String(describing: pageDetails), privacy: .public)")
                    self.context.pageDetails = pageDetails
                } catch {
                    Logger.appExtension.error("Error decoding page details JSON. Error: \(error, privacy: .public)")
                }
            }

            Logger.appExtension.debug("Processing web URL provider. URL: \(self.context.urlString ?? "nil", privacy: .public)")
        }
    }
}
