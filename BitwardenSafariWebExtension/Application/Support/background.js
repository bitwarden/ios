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

function bitwardenMessageToRequest(message) {
  if (message?.request && typeof message.request === "object") {
    return message.request;
  }

  switch (message?.type) {
    case "bitwarden:change-password":
      return { kind: "changePassword" };
    case "bitwarden:fill":
      return { kind: "fill" };
    case "bitwarden:generate-password":
      return { kind: "generatePassword" };
    case "bitwarden:save-login":
      return { kind: "saveLogin" };
    case "bitwarden:setup":
      return { kind: "setup" };
    default:
      return null;
  }
}

browser.runtime.onMessage.addListener((message) => {
  const request = bitwardenMessageToRequest(message);
  if (request) {
    return bitwardenSendNativeRequest(request);
  }

  if (message?.type === "bitwarden:ping") {
    return Promise.resolve({ type: "bitwarden:pong" });
  }

  return false;
});
