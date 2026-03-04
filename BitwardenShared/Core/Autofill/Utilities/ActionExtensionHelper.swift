import BitwardenKit
import Foundation
import OSLog
import UniformTypeIdentifiers

// swiftlint:disable file_length

// MARK: - ActionExtensionHelper

/// A helper class for processing the input items of the action extension.
///
public class ActionExtensionHelper { // swiftlint:disable:this type_body_length
    // MARK: Properties

    /// The app's route that the app should navigate to after auth has been completed.
    public var authCompletionRoute: AppRoute {
        if isAppExtensionSetup {
            AppRoute.extensionSetup(.extensionActivation(type: .appExtension))
        } else if isProviderSaveLogin {
            AppRoute.vault(
                .addItem(
                    group: .login,
                    newCipherOptions: NewCipherOptions(
                        name: context.loginTitle,
                        password: context.password,
                        uri: context.urlString,
                        username: context.username,
                    ),
                    type: .login,
                ),
            )
        } else {
            AppRoute.vault(.autofillList)
        }
    }

    /// Whether the app extension can autofill credentials.
    public var canAutofill: Bool {
        guard context.providerType == Constants.UTType.appExtensionFillBrowserAction ||
            context.providerType == Constants.UTType.appExtensionFillWebViewAction ||
            context.providerType == UTType.propertyList.identifier ||
            context.providerType == UTType.url.identifier
        else {
            return false
        }
        return context.pageDetails?.hasPasswordField ?? false
    }

    /// Whether the app extension setup provider was included in the input items.
    public var isAppExtensionSetup: Bool {
        context.providerType == Constants.UTType.appExtensionSetup
    }

    /// Whether the app extension save login provider was included in the input items.
    public var isProviderSaveLogin: Bool {
        context.providerType == Constants.UTType.appExtensionSaveLogin
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
                    processFindLoginProvider(provider) ||
                    processFindLoginBrowserProvider(provider, type: Constants.UTType.appExtensionFillBrowserAction) ||
                    processFindLoginBrowserProvider(provider, type: Constants.UTType.appExtensionFillWebViewAction) ||
                    processFindLoginBrowserProvider(provider, type: UTType.url.identifier) ||
                    processSaveLoginProvider(provider) ||
                    processChangePasswordProvider(provider) ||
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
    ///   - fields: A list of additional fields to fill.
    /// - Returns: A dictionary of the item data used to complete the extension request.
    ///
    public func itemDataToCompleteRequest(
        username: String,
        password: String,
        fields: [(String, String)],
    ) -> [String: Any] {
        var itemData = [String: Any]()

        if context.providerType == UTType.propertyList.identifier {
            let fillScript = FillScript(
                pageDetails: context.pageDetails,
                fillUsername: username,
                fillPassword: password,
                fillFields: fields,
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
        } else if context.providerType == Constants.UTType.appExtensionFindLoginAction ||
            context.providerType == Constants.UTType.appExtensionSaveLogin {
            itemData[Constants.appExtensionUsernameKey] = username
            itemData[Constants.appExtensionPasswordKey] = password
        } else if context.providerType == Constants.UTType.appExtensionFillBrowserAction ||
            context.providerType == Constants.UTType.appExtensionFillWebViewAction {
            let fillScript = FillScript(
                pageDetails: context.pageDetails,
                fillUsername: username,
                fillPassword: password,
                fillFields: fields,
            )
            do {
                let scriptJsonData = try JSONEncoder().encode(fillScript)
                if let scriptJson = String(data: scriptJsonData, encoding: .utf8) {
                    let scriptDictionary = [Constants.appExtensionWebViewPageFillScript: scriptJson]
                    itemData[Constants.appExtensionWebViewPageFillScript] = scriptDictionary
                }
            } catch {
                Logger.application.error("Error encoding fill script. Error: \(error, privacy: .public)")
            }
        } else if context.providerType == Constants.UTType.appExtensionChangePasswordAction {
            itemData[Constants.appExtensionPasswordKey] = ""
            itemData[Constants.appExtensionOldPasswordKey] = password
        }

        return itemData
    }

    // MARK: Private

    /// Decodes the `PageDetails` object from the dictionary.
    ///
    /// - Parameter dictionary: The dictionary containing the item provider's data.
    /// - Returns: The decoded `PageDetails` object.
    ///
    private func decodePageDetails(from dictionary: [AnyHashable: Any]) -> PageDetails? {
        guard let pageDetailsJson = dictionary[Constants.appExtensionWebViewPageDetails] as? String else {
            Logger.appExtension.error(
                """
                Error unable to find JSON string for the \(Constants.appExtensionWebViewPageDetails) key.
                """,
            )
            return nil
        }

        do {
            return try JSONDecoder().decode(PageDetails.self, from: Data(pageDetailsJson.utf8))
        } catch {
            Logger.appExtension.error("Error decoding page details JSON. Error: \(error, privacy: .public)")
            return nil
        }
    }

    /// Decodes the `PasswordGenerationOptions` object from the dictionary
    ///
    /// - Parameter dictionary: The dictionary containing the item provider's data.
    /// - Returns: The decoded `PageDetails` object.
    ///
    private func decodePasswordOptions(from dictionary: [AnyHashable: Any]) -> PasswordGenerationOptions? {
        guard let passwordOptionsDictionary = dictionary[Constants.appExtensionPasswordGeneratorOptionsKey]
            as? [AnyHashable: Any] else { return nil }

        do {
            let passwordOptionsData = try JSONSerialization.data(withJSONObject: passwordOptionsDictionary)
            return try JSONDecoder().decode(PasswordGenerationOptions.self, from: passwordOptionsData)
        } catch {
            Logger.appExtension.error("Error decoding password options JSON. Error: \(error, privacy: .public)")
            return nil
        }
    }

    /// Processes a potential `NSItemProvider` to determine if it conforms to the change password
    /// action type.
    ///
    /// - Parameter itemProvider: The `NSItemProvider` to process.
    /// - Returns: Whether the item provider conforms to the change password action type.
    ///
    private func processChangePasswordProvider(_ itemProvider: NSItemProvider) -> Bool {
        processItemProvider(
            itemProvider,
            type: Constants.UTType.appExtensionChangePasswordAction,
            dictionaryHandler: { dictionary in
                defer { self.context.didFinishLoadingItem = true }

                self.context.loginTitle = dictionary[Constants.appExtensionTitleKey] as? String
                self.context.notes = dictionary[Constants.appExtensionNotesKey] as? String
                self.context.oldPassword = dictionary[Constants.appExtensionOldPasswordKey] as? String
                self.context.password = dictionary[Constants.appExtensionPasswordKey] as? String
                self.context.passwordOptions = self.decodePasswordOptions(from: dictionary)
                self.context.urlString = dictionary[Constants.appExtensionUrlStringKey] as? String
                self.context.username = dictionary[Constants.appExtensionUsernameKey] as? String

                Logger.appExtension.debug("Processed change password provider")
            },
        )
    }

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

    /// Processes a potential `NSItemProvider` to determine if it conforms to the find login browser
    /// action type.
    ///
    /// - Parameters:
    ///   - itemProvider: The `NSItemProvider` to process.
    ///   - type: The type identifier to check that the item provider conforms to.
    /// - Returns: Whether the item provider conforms to the change password action type.
    ///
    private func processFindLoginBrowserProvider(_ itemProvider: NSItemProvider, type: String) -> Bool {
        processItemProvider(itemProvider, type: type) { dictionary in
            defer { self.context.didFinishLoadingItem = true }

            self.context.urlString = dictionary[Constants.appExtensionUrlStringKey] as? String
            self.context.pageDetails = self.decodePageDetails(from: dictionary)

            Logger.appExtension.debug(
                """
                Processed find login browser provider. \
                URL: \(String(describing: self.context.urlString), privacy: .public)")
                """,
            )
        } urlHandler: { url in
            defer { self.context.didFinishLoadingItem = true }

            self.context.urlString = url.absoluteString

            Logger.appExtension.debug(
                """
                Processed find login browser provider. URL: \(url.absoluteString, privacy: .public)
                """,
            )
        }
    }

    /// Processes a potential `NSItemProvider` to determine if it conforms to the find login action type.
    ///
    /// - Parameter itemProvider: The `NSItemProvider` to process.
    /// - Returns: Whether the item provider conforms to the find login action type.
    ///
    private func processFindLoginProvider(_ itemProvider: NSItemProvider) -> Bool {
        processItemProvider(
            itemProvider,
            type: Constants.UTType.appExtensionFindLoginAction,
            dictionaryHandler: { dictionary in
                defer { self.context.didFinishLoadingItem = true }

                self.context.urlString = dictionary[Constants.appExtensionUrlStringKey] as? String

                Logger.appExtension.debug(
                    """
                    Processed find login provider. \
                    URL: \(String(describing: self.context.urlString), privacy: .public)")
                    """,
                )
            },
        )
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
        urlHandler: ((URL) -> Void)? = nil,
    ) -> Bool {
        guard itemProvider.hasItemConformingToTypeIdentifier(type) else { return false }
        itemProvider.loadItem(forTypeIdentifier: type) { item, error in
            guard let item else {
                Logger.appExtension.error("Unable to load item for type \(type). Error: \(String(describing: error))")
                return
            }

            self.context.providerType = type

            Logger.appExtension.debug(
                """
                Loaded item for type \(type). Item: \(String(describing: item), privacy: .public)
                """,
            )

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

    /// Processes a potential `NSItemProvider` to determine if it conforms to the save login action type.
    ///
    /// - Parameter itemProvider: The `NSItemProvider` to process.
    /// - Returns: Whether the item provider conforms to the save login action type.
    ///
    private func processSaveLoginProvider(_ itemProvider: NSItemProvider) -> Bool {
        processItemProvider(
            itemProvider,
            type: Constants.UTType.appExtensionSaveLogin,
            dictionaryHandler: { dictionary in
                defer { self.context.didFinishLoadingItem = true }

                self.context.loginTitle = dictionary[Constants.appExtensionTitleKey] as? String
                self.context.notes = dictionary[Constants.appExtensionNotesKey] as? String
                self.context.password = dictionary[Constants.appExtensionPasswordKey] as? String
                self.context.passwordOptions = self.decodePasswordOptions(from: dictionary)
                self.context.urlString = dictionary[Constants.appExtensionUrlStringKey] as? String
                self.context.username = dictionary[Constants.appExtensionUsernameKey] as? String

                Logger.appExtension.debug("Processed save login browser provider")
            },
        )
    }

    /// Processes a potential `NSItemProvider` to determine if it conforms to a property list type
    /// to autofill credentials on a web page
    ///
    /// - Parameter itemProvider: The `NSItemProvider` to process.
    /// - Returns: Whether the item provider conforms to the property list type.
    ///
    private func processWebUrlProvider(_ itemProvider: NSItemProvider) -> Bool {
        processItemProvider(itemProvider, type: UTType.propertyList.identifier, dictionaryHandler: { dictionary in
            defer { self.context.didFinishLoadingItem = true }

            guard let result = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: String]
            else { return }

            self.context.urlString = result[Constants.appExtensionUrlStringKey]
            self.context.pageDetails = self.decodePageDetails(from: result)

            Logger.appExtension.debug(
                """
                Processing web URL provider. URL: \(self.context.urlString ?? "nil", privacy: .public)
                """,
            )
        })
    }
}
