// background.js

function sendToNative(message) {
    return new Promise((resolve, reject) => {
        browser.runtime.sendNativeMessage("application.id", message, (response) => {
            if (browser.runtime.lastError) {
                reject(browser.runtime.lastError);
            } else {
                resolve(response);
            }
        });
    });
}

browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
    console.log("Background received message from content script:", message);

    // Route messages to native iOS app
    if (message.type === "vaultStatus" || message.type === "getItems" || message.type === "unlock" || message.type === "unlockWithPassword" || message.type === "lock") {
        sendToNative(message).then(response => {
            sendResponse(response);
        }).catch(err => {
            console.error("Native messaging error:", err);
            sendResponse({ error: err.message });
        });

        return true; // Keep message channel open for async response
    }

    // Open the native extension popup sheet programmatically.
    // Called from the inline popover (content.js) when the vault is locked.
    if (message.type === "openPopup") {
        if (browser.action && browser.action.openPopup) {
            browser.action.openPopup().then(() => {
                sendResponse({ status: "opened" });
            }).catch(e => {
                console.error("Failed to open popup:", e);
                sendResponse({ error: e.toString() });
            });
            return true;
        } else {
            sendResponse({ error: "browser.action.openPopup is not available" });
            return false;
        }
    }

    // Broadcast fill command to all frames in the sender's tab
    if (message.type === "broadcastFill" && sender.tab && sender.tab.id) {
        // To send to all frames, we must iterate through them if the browser defaults to top-frame only.
        // Safari usually supports browser.webNavigation.getAllFrames.
        if (browser.webNavigation && browser.webNavigation.getAllFrames) {
            browser.webNavigation.getAllFrames({ tabId: sender.tab.id }).then((frames) => {
                frames.forEach(frame => {
                    browser.tabs.sendMessage(
                        sender.tab.id,
                        { type: "performBroadcastFill", item: message.item },
                        { frameId: frame.frameId }
                    ).catch(() => { }); // Ignore errors for frames that might not have content scripts
                });
                sendResponse({ status: "broadcast sequence initiated via webNavigation" });
            });
        } else {
            // Fallback: try to just broadcast and hope the polyfill/browser handles it
            browser.tabs.sendMessage(sender.tab.id, {
                type: "performBroadcastFill",
                item: message.item
            }).catch(() => { });
            sendResponse({ status: "broadcast sequence initiated (fallback)" });
        }
        return true;
    }
});
