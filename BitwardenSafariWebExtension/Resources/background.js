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
});
