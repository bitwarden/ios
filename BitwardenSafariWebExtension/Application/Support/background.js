browser.runtime.onInstalled.addListener(() => {
  console.log("Bitwarden Safari Web Extension scaffold installed.");
});

function bitwardenParseNativeResponse(nativeResponse) {
  const message = nativeResponse?.message;
  if (typeof message !== "string") {
    return nativeResponse;
  }

  try {
    return JSON.parse(message);
  } catch {
    return {
      errorMessage: "Invalid native response payload",
      id: null,
      response: null,
    };
  }
}

async function bitwardenSendNativeRequest(request) {
  const bridgeRequest = {
    id: crypto.randomUUID(),
    request,
  };
  const nativeResponse = await browser.runtime.sendNativeMessage("bitwarden", {
    message: JSON.stringify(bridgeRequest),
  });

  return bitwardenParseNativeResponse(nativeResponse);
}

browser.runtime.onMessage.addListener((message) => {
  if (message?.type === "bitwarden:generate-password") {
    return bitwardenSendNativeRequest({ kind: "generatePassword" });
  }

  if (message?.type === "bitwarden:ping") {
    return Promise.resolve({ type: "bitwarden:pong" });
  }

  return false;
});
