import BitwardenKit
import BitwardenShared
import Combine
import Foundation
import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private let logger = OSLog(subsystem: "com.8bit.bitwarden", category: "SafariWebExtensionHandler")

    func beginRequest(with context: NSExtensionContext) {
        guard let item = context.inputItems.first as? NSExtensionItem,
              let userInfo = item.userInfo as? [String: Any],
              let message = userInfo[SFExtensionMessageKey] as? [String: Any] else {
            os_log("Failed to parse request message", log: logger, type: .error)
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        os_log("Received message from browser.runtime.sendNativeMessage: %{public}s", log: logger, type: .default, String(describing: message))
        
        let type = message["type"] as? String ?? ""
        
        // Handle message types
        switch type {
        case "vaultStatus":
            Task { @MainActor in
                await handleVaultStatus(context: context)
            }
        case "getItems":
            let url = message["url"] as? String ?? ""
            Task { @MainActor in
                await handleGetItems(url: url, context: context)
            }
        default:
            sendResponse(["error": "Unknown message type: \(type)"], to: context)
        }
    }
    
    // MARK: - Handlers
    
    @MainActor
    private func handleVaultStatus(context: NSExtensionContext) async {
        let errorReporter = OSLogErrorReporter()
        let services = ServiceContainer(appContext: .appExtension, errorReporter: errorReporter)
        let appModule = DefaultAppModule(services: services)
        let appProcessor = AppProcessor(appModule: appModule, services: services)
        
        let isLocked = await appProcessor.isLocked()
        let hasAccount = await appProcessor.hasAccount()
        
        let status = if !hasAccount {
            "unauthenticated"
        } else if isLocked {
            "locked"
        } else {
            "unlocked"
        }
        
        sendResponse(["status": status], to: context)
    }
    
    @MainActor
    private func handleGetItems(url: String, context: NSExtensionContext) async {
        let errorReporter = OSLogErrorReporter()
        let services = ServiceContainer(appContext: .appExtension, errorReporter: errorReporter)
        let appModule = DefaultAppModule(services: services)
        let appProcessor = AppProcessor(appModule: appModule, services: services)
        
        let isLocked = await appProcessor.isLocked()
        if isLocked {
            sendResponse(["error": "Vault is locked"], to: context)
            return
        }
        
        do {
            let vaultData = try await appProcessor.fetchVault()
            var responseItems: [[String: Any]] = []
            
            // Filter vault data by URL (basic implementation for now)
            // In a real implementation this should use Bitwarden's MatchService
            for listView in vaultData {
                let fullCipher = try await appProcessor.fetchCipher(from: listView)
                guard let login = fullCipher.login else { continue }
                
                // Simplified matching logic: just check if any URI contains the host
                let matched = login.uris?.contains(where: { uri in
                    guard let uriStr = uri.uri, let urlObj = URL(string: url), let host = urlObj.host else { return false }
                    return uriStr.contains(host)
                }) ?? false
                
                if matched {
                    responseItems.append([
                        "id": fullCipher.id ?? "",
                        "name": fullCipher.name,
                        "username": login.username ?? "",
                        "password": login.password ?? ""
                    ])
                }
            }
            
            sendResponse(["items": responseItems], to: context)
        } catch {
            os_log("Failed to read vault data: %{public}s", log: logger, type: .error, String(describing: error))
            sendResponse(["error": "Failed to read vault"], to: context)
        }
    }
    
    // MARK: - Helpers
    
    private func sendResponse(_ response: [String: Any], to context: NSExtensionContext) {
        let responseItem = NSExtensionItem()
        responseItem.userInfo = [SFExtensionMessageKey: response]
        context.completeRequest(returningItems: [responseItem], completionHandler: nil)
    }
}
