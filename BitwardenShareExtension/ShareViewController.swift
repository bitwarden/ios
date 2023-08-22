import Social
import UIKit

class ShareViewController: SLComposeServiceViewController {
    // Automatically generated SLComposeServiceViewController. Should be updated to match our use.

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext
        // attachments.

        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's
        // -didSelectPost, which will similarly complete the extension context.
        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of
        // SLComposeSheetConfigurationItem here.
        []
    }
}
