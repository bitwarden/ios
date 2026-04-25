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

  try {
    const nativeResponse = await browser.runtime.sendNativeMessage("bitwarden", {
      message: JSON.stringify(bridgeRequest),
    });

    return bitwardenParseNativeResponse(nativeResponse);
  } catch (error) {
    return {
      id: bridgeRequest.id,
      response: null,
      errorMessage: error && typeof error.message === 'string' && error.message.length > 0
        ? error.message
        : 'Couldn’t reach the Bitwarden native host.',
    };
  }
}

function bitwardenMergeRequestContext(request, requestContext) {
  if (!request || typeof request !== "object") {
    return request;
  }
  if (!requestContext || typeof requestContext !== "object") {
    return request;
  }
  return {
    ...request,
    requestContext,
  };
}

function bitwardenMessageToRequest(message) {
  if (message?.request && typeof message.request === "object") {
    return bitwardenMergeRequestContext(message.request, message.requestContext);
  }

  let request = null;
  switch (message?.type) {
    case "bitwarden:change-password":
      request = { kind: "changePassword" };
      break;
    case "bitwarden:fill":
      request = { kind: "fill" };
      break;
    case "bitwarden:generate-password":
      request = { kind: "generatePassword" };
      break;
    case "bitwarden:save-login":
      request = { kind: "saveLogin" };
      break;
    case "bitwarden:setup":
      request = { kind: "setup" };
      break;
    default:
      request = null;
      break;
  }

  return bitwardenMergeRequestContext(request, message?.requestContext);
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
