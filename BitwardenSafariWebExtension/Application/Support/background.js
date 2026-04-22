browser.runtime.onInstalled.addListener(() => {
  console.log("Bitwarden Safari Web Extension scaffold installed.");
});

browser.runtime.onMessage.addListener((message) => {
  if (message?.type === "bitwarden:ping") {
    return Promise.resolve({ type: "bitwarden:pong" });
  }

  return false;
});
