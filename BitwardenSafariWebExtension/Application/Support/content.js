(() => {
  function bitwardenUUID() {
    return crypto.randomUUID();
  }

  function bitwardenCurrentURL() {
    return window.location.href;
  }

  function bitwardenTrimmedValue(value) {
    if (typeof value !== "string") {
      return null;
    }

    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : null;
  }

  function bitwardenFieldType(element) {
    const type = (element.getAttribute("type") || element.type || "text").toLowerCase();
    return type.length > 0 ? type : "text";
  }

  function bitwardenIsVisible(element) {
    const style = window.getComputedStyle(element);
    if (style.display === "none" || style.visibility === "hidden") {
      return false;
    }

    const rect = element.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0;
  }

  function bitwardenLabelText(element) {
    if (element.labels && element.labels.length > 0) {
      return bitwardenTrimmedValue(
        Array.from(element.labels)
          .map((label) => label.textContent || "")
          .join(" "),
      );
    }

    const ariaLabel = bitwardenTrimmedValue(element.getAttribute("aria-label"));
    if (ariaLabel) {
      return ariaLabel;
    }

    const placeholder = bitwardenTrimmedValue(element.getAttribute("placeholder"));
    if (placeholder) {
      return placeholder;
    }

    return null;
  }

  function bitwardenCollectForms(document) {
    return Array.from(document.querySelectorAll("form")).reduce((forms, form, index) => {
      const opid = form.dataset.bitwardenOpid || `form__${index}`;
      form.dataset.bitwardenOpid = opid;
      forms[opid] = {
        htmlAction: form.action || bitwardenCurrentURL(),
        htmlID: form.id || opid,
        htmlMethod: (form.method || "get").toLowerCase(),
        htmlName: form.name || form.id || opid,
        opid,
      };
      return forms;
    }, {});
  }

  function bitwardenCollectFields(document) {
    const selector = "input, select, textarea, button";
    return Array.from(document.querySelectorAll(selector)).map((element, index) => {
      const opid = element.dataset.bitwardenOpid || `field__${index}`;
      element.dataset.bitwardenOpid = opid;
      const label = bitwardenLabelText(element);
      return {
        disabled: element.disabled || false,
        elementNumber: index,
        form: element.form?.dataset.bitwardenOpid || null,
        htmlClass: bitwardenTrimmedValue(element.className),
        htmlID: bitwardenTrimmedValue(element.id),
        htmlName: bitwardenTrimmedValue(element.name),
        "label-left": label,
        "label-right": null,
        "label-tag": label,
        onepasswordFieldType: bitwardenFieldType(element),
        opid,
        placeholder: bitwardenTrimmedValue(element.getAttribute("placeholder")),
        readOnly: element.readOnly || false,
        type: bitwardenFieldType(element),
        value: bitwardenTrimmedValue(element.value),
        viewable: bitwardenIsVisible(element),
        visible: bitwardenIsVisible(element),
      };
    });
  }

  function bitwardenCollectPageDetails(document = window.document) {
    const forms = bitwardenCollectForms(document);
    const fields = bitwardenCollectFields(document);
    return {
      collectedTimestamp: new Date().toISOString(),
      documentUUID: document.documentElement.dataset.bitwardenDocumentUUID || bitwardenUUID(),
      documentUrl: document.location.href,
      fields,
      forms,
      tabUrl: window.location.href,
      title: document.title || "",
      url: document.location.href,
    };
  }

  function bitwardenFirstFieldValue(pageDetails, predicate) {
    const field = pageDetails.fields.find(predicate);
    return field?.value || null;
  }

  function bitwardenPasswordFieldRole(field) {
    const source = [field.htmlID, field.htmlName, field['label-tag'], field['label-left'], field.placeholder]
      .filter((value) => typeof value === 'string' && value.length > 0)
      .join(' ')
      .toLowerCase();

    if (/(current|old)/.test(source)) {
      return 'current';
    }
    if (/(confirm|verification|verify|repeat|again)/.test(source)) {
      return 'confirm';
    }
    if (/(new|create|choose|set)/.test(source)) {
      return 'new';
    }
    return 'unknown';
  }

  function bitwardenBuildRequest(kind, overrides = {}) {
    return {
      id: bitwardenUUID(),
      request: {
        kind,
        ...overrides,
      },
    };
  }

  function bitwardenBuildFillRequest() {
    return bitwardenBuildRequest("fill", {
      pageDetails: bitwardenCollectPageDetails(),
      urlString: bitwardenCurrentURL(),
    });
  }

  function bitwardenBuildSaveLoginRequest() {
    const pageDetails = bitwardenCollectPageDetails();
    const username = bitwardenFirstFieldValue(
      pageDetails,
      (field) => ["email", "text", "tel"].includes(field.type) && field.viewable,
    );
    const password = bitwardenFirstFieldValue(
      pageDetails,
      (field) => field.type === "password" && field.viewable,
    );

    return bitwardenBuildRequest("saveLogin", {
      loginTitle: document.title || null,
      pageDetails,
      password,
      urlString: bitwardenCurrentURL(),
      username,
    });
  }

  function bitwardenBuildChangePasswordRequest() {
    const pageDetails = bitwardenCollectPageDetails();
    const passwordFields = pageDetails.fields.filter((field) => field.type === "password");
    const currentPasswordField = passwordFields.find((field) => bitwardenPasswordFieldRole(field) === 'current') || passwordFields.at(0) || null;
    const newPasswordField = passwordFields.find((field) => bitwardenPasswordFieldRole(field) === 'new')
      || passwordFields.find((field) => bitwardenPasswordFieldRole(field) === 'unknown' && field !== currentPasswordField)
      || passwordFields.at(-1)
      || null;

    return bitwardenBuildRequest("changePassword", {
      loginTitle: document.title || null,
      oldPassword: currentPasswordField?.value || null,
      pageDetails,
      password: newPasswordField?.value || null,
      urlString: bitwardenCurrentURL(),
    });
  }

  function bitwardenBuildGeneratePasswordRequest() {
    return bitwardenBuildRequest("generatePassword", {
      pageDetails: bitwardenCollectPageDetails(),
      urlString: bitwardenCurrentURL(),
    });
  }

  function bitwardenBuildSetupRequest() {
    return bitwardenBuildRequest("setup", {
      urlString: bitwardenCurrentURL(),
    });
  }

  function bitwardenElements(document = window.document) {
    return Array.from(document.querySelectorAll("input, select, textarea, button"));
  }

  function bitwardenElementByOpid(opid, document = window.document) {
    if (!opid) {
      return null;
    }

    const elements = bitwardenElements(document);
    const exactMatch = elements.find((element) => element.dataset.bitwardenOpid === opid);
    if (exactMatch) {
      return exactMatch;
    }

    const index = Number.parseInt(String(opid).split("__").at(-1), 10);
    return Number.isNaN(index) ? null : elements[index] || null;
  }

  function bitwardenDispatchInputEvents(element) {
    if (!element || typeof element.dispatchEvent !== "function") {
      return;
    }

    element.dispatchEvent({ type: "input", target: element });
    element.dispatchEvent({ type: "change", target: element });
  }

  function bitwardenSetElementValue(element, value) {
    if (!element || element.disabled || element.readOnly || typeof value !== "string") {
      return false;
    }

    if (typeof element.focus === "function") {
      element.focus();
    }
    element.value = value;
    bitwardenDispatchInputEvents(element);
    return true;
  }

  function bitwardenParseFillScript(fillScriptJSON) {
    if (typeof fillScriptJSON !== "string" || fillScriptJSON.length === 0) {
      return null;
    }

    try {
      return JSON.parse(fillScriptJSON);
    } catch {
      return null;
    }
  }

  function bitwardenApplyFillScript(fillScriptJSON, document = window.document) {
    const fillScript = bitwardenParseFillScript(fillScriptJSON);
    if (!fillScript || !Array.isArray(fillScript.script)) {
      return false;
    }

    let applied = false;
    for (const step of fillScript.script) {
      if (!Array.isArray(step) || step.length === 0) {
        continue;
      }

      const [operation, opid, value] = step;
      const element = bitwardenElementByOpid(opid, document);
      if (!element) {
        continue;
      }

      switch (operation) {
        case "click_on_opid":
          if (typeof element.click === "function") {
            element.click();
          }
          break;
        case "fill_by_opid":
          applied = bitwardenSetElementValue(element, value) || applied;
          break;
        case "focus_by_opid":
          if (typeof element.focus === "function") {
            element.focus();
          }
          break;
        default:
          break;
      }
    }

    return applied;
  }

  function bitwardenApplyGeneratedPassword(generatedPassword, document = window.document) {
    if (typeof generatedPassword !== "string" || generatedPassword.length === 0) {
      return false;
    }

    const passwordFields = bitwardenElements(document).filter(
      (field) => bitwardenFieldType(field) === "password" && !field.disabled && !field.readOnly,
    );
    if (passwordFields.length === 0) {
      return false;
    }

    let applied = false;
    for (const field of passwordFields) {
      applied = bitwardenSetElementValue(field, generatedPassword) || applied;
    }
    return applied;
  }

  function bitwardenRemoveStatusBanner(document = window.document) {
    const existingBanner = document.body?.querySelector?.('[data-bitwarden-status-banner]');
    if (existingBanner && typeof existingBanner.remove === "function") {
      existingBanner.remove();
    }
  }

  function bitwardenRemoveActionPanel(document = window.document) {
    const existingPanel = document.body?.querySelector?.('[data-bitwarden-action-panel]');
    if (existingPanel && typeof existingPanel.remove === "function") {
      existingPanel.remove();
    }
  }

  function bitwardenNeedsActionPanel(submissionAction) {
    return ["saveNewLogin", "updateExistingLogin", "updatePassword"].includes(submissionAction);
  }

  function bitwardenActionPanelContent(response) {
    switch (response?.submissionAction) {
      case "saveNewLogin":
        return {
          title: "Save login",
          subtitle: response.userMessage || "Save this login to Bitwarden.",
          primaryLabel: "Save in Bitwarden",
          dismissLabel: "Not now",
        };
      case "updateExistingLogin":
        return {
          title: "Update login",
          subtitle: response.userMessage || "Update the existing Bitwarden login with these changes.",
          primaryLabel: "Update in Bitwarden",
          dismissLabel: "Not now",
        };
      case "updatePassword":
        return {
          title: "Update password",
          subtitle: response.userMessage || "Update the password for this Bitwarden login.",
          primaryLabel: "Update in Bitwarden",
          dismissLabel: "Not now",
        };
      default:
        return null;
    }
  }

  function bitwardenPresentActionPanel(nativeResponse, document = window.document) {
    const response = nativeResponse?.response;
    if (!document?.body || !response || !bitwardenNeedsActionPanel(response.submissionAction)) {
      return null;
    }

    const content = bitwardenActionPanelContent(response);
    if (!content) {
      return null;
    }

    bitwardenRemoveActionPanel(document);

    const panel = document.createElement('div');
    panel.dataset.bitwardenActionPanel = 'true';
    panel.dataset.bitwardenActionKind = response.submissionAction;
    panel.role = 'dialog';
    panel.textContent = `${content.title}\n${content.subtitle}\n${content.primaryLabel}\n${content.dismissLabel}`;
    const primaryButton = document.createElement('button');
    primaryButton.dataset.bitwardenActionPrimary = 'true';
    primaryButton.textContent = content.primaryLabel;
    primaryButton.onclick = () => {
      bitwardenDispatchActionEvent({ action: response.submissionAction, confirmed: true });
      if (typeof panel.remove === 'function') {
        panel.remove();
      }
    };
    const dismissButton = document.createElement('button');
    dismissButton.dataset.bitwardenActionDismiss = 'true';
    dismissButton.textContent = content.dismissLabel;
    dismissButton.onclick = () => {
      if (typeof panel.remove === 'function') {
        panel.remove();
      }
    };
    if (typeof panel.appendChild === 'function') {
      panel.appendChild(primaryButton);
      panel.appendChild(dismissButton);
    }
    panel.style.position = 'fixed';
    panel.style.top = '16px';
    panel.style.left = '16px';
    panel.style.right = '16px';
    panel.style.zIndex = '2147483647';
    panel.style.padding = '16px';
    panel.style.borderRadius = '18px';
    panel.style.background = 'rgba(255, 255, 255, 0.96)';
    panel.style.color = '#111';
    panel.style.fontSize = '14px';
    panel.style.fontFamily = '-apple-system, BlinkMacSystemFont, sans-serif';
    panel.style.boxShadow = '0 16px 40px rgba(0, 0, 0, 0.16)';
    panel.style.backdropFilter = 'blur(20px)';
    panel.style.border = '1px solid rgba(60, 60, 67, 0.12)';
    document.body.appendChild(panel);
    return panel;
  }

  function bitwardenPresentStatusBanner(message, document = window.document) {
    if (!document?.body || typeof message !== "string" || message.length === 0) {
      return null;
    }

    bitwardenRemoveStatusBanner(document);

    const banner = document.createElement('div');
    banner.dataset.bitwardenStatusBanner = 'true';
    banner.role = 'status';
    banner.textContent = message;
    banner.style.position = 'fixed';
    banner.style.left = '16px';
    banner.style.right = '16px';
    banner.style.bottom = '16px';
    banner.style.zIndex = '2147483647';
    banner.style.padding = '12px 16px';
    banner.style.borderRadius = '14px';
    banner.style.background = 'rgba(28, 28, 30, 0.92)';
    banner.style.color = '#fff';
    banner.style.fontSize = '14px';
    banner.style.fontFamily = '-apple-system, BlinkMacSystemFont, sans-serif';
    banner.style.boxShadow = '0 10px 30px rgba(0, 0, 0, 0.2)';
    document.body.appendChild(banner);
    setTimeout(() => {
      if (typeof banner.remove === "function") {
        banner.remove();
      }
    }, 4000);
    return banner;
  }

  function bitwardenDispatchActionEvent(detail) {
    const event = typeof CustomEvent === "function"
      ? new CustomEvent("bitwarden:safari-extension-action", { detail })
      : { type: "bitwarden:safari-extension-action", detail };

    if (typeof window.dispatchEvent === "function") {
      window.dispatchEvent(event);
    }
    if (typeof document.dispatchEvent === "function") {
      document.dispatchEvent(event);
    }
  }

  function bitwardenDispatchStatusEvent(nativeResponse) {
    const detail = nativeResponse;
    const event = typeof CustomEvent === "function"
      ? new CustomEvent("bitwarden:safari-extension-response", { detail })
      : { type: "bitwarden:safari-extension-response", detail };

    if (typeof window.dispatchEvent === "function") {
      window.dispatchEvent(event);
    }
    if (typeof document.dispatchEvent === "function") {
      document.dispatchEvent(event);
    }
  }

  async function bitwardenApplyNativeResponse(nativeResponse) {
    const response = nativeResponse?.response;
    if (!response || typeof response !== "object") {
      return nativeResponse;
    }

    window.bitwardenSafariWebExtension.lastNativeResponse = nativeResponse;

    if (response.submissionAction === "fill" && typeof response.fillScriptJSON === "string") {
      bitwardenApplyFillScript(response.fillScriptJSON);
    }

    if (typeof response.generatedPassword === "string" && response.generatedPassword.length > 0) {
      bitwardenApplyGeneratedPassword(response.generatedPassword);
    }

    if (typeof response.userMessage === "string" && response.userMessage.length > 0) {
      bitwardenPresentStatusBanner(response.userMessage);
    }

    bitwardenPresentActionPanel(nativeResponse);

    bitwardenDispatchStatusEvent(nativeResponse);
    return nativeResponse;
  }

  async function bitwardenSendBuiltRequest(type, requestBuilder) {
    const nativeResponse = await browser.runtime.sendMessage({
      type,
      request: requestBuilder().request,
    });
    return bitwardenApplyNativeResponse(nativeResponse);
  }

  window.bitwardenSafariWebExtension = {
    applyGeneratedPassword: bitwardenApplyGeneratedPassword,
    applyFillScript: bitwardenApplyFillScript,
    applyNativeResponse: bitwardenApplyNativeResponse,
    presentActionPanel: bitwardenPresentActionPanel,
    presentStatusBanner: bitwardenPresentStatusBanner,
    buildRequest: bitwardenBuildRequest,
    buildChangePasswordRequest: bitwardenBuildChangePasswordRequest,
    buildFillRequest: bitwardenBuildFillRequest,
    buildGeneratePasswordRequest: bitwardenBuildGeneratePasswordRequest,
    buildSaveLoginRequest: bitwardenBuildSaveLoginRequest,
    buildSetupRequest: bitwardenBuildSetupRequest,
    collectPageDetails: bitwardenCollectPageDetails,
    generatePassword: () => bitwardenSendBuiltRequest("bitwarden:generate-password", bitwardenBuildGeneratePasswordRequest),
    requestFill: () => bitwardenSendBuiltRequest("bitwarden:fill", bitwardenBuildFillRequest),
    requestSaveLogin: () => bitwardenSendBuiltRequest("bitwarden:save-login", bitwardenBuildSaveLoginRequest),
    requestChangePassword: () => bitwardenSendBuiltRequest("bitwarden:change-password", bitwardenBuildChangePasswordRequest),
    requestSetup: () => bitwardenSendBuiltRequest("bitwarden:setup", bitwardenBuildSetupRequest),
  };
})();
