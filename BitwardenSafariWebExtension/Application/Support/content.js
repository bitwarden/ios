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

  function bitwardenPreferredUsernameField(fields) {
    return fields.find((field) => field.type === 'email' && field.viewable)
      || fields.find((field) => field.type === 'text' && field.viewable)
      || fields.find((field) => field.type === 'tel' && field.viewable)
      || null;
  }

  function bitwardenPreferredSavePasswordField(fields) {
    const passwordFields = fields.filter((field) => field.type === 'password' && field.viewable);
    return passwordFields.find((field) => bitwardenPasswordFieldRole(field) === 'new')
      || passwordFields.find((field) => bitwardenPasswordFieldRole(field) === 'unknown')
      || passwordFields.find((field) => bitwardenPasswordFieldRole(field) !== 'confirm')
      || null;
  }

  function bitwardenFieldText(field) {
    return [field.htmlID, field.htmlName, field['label-tag'], field['label-left'], field.placeholder]
      .filter((value) => typeof value === 'string' && value.length > 0)
      .join(' ')
      .toLowerCase();
  }

  function bitwardenLooksLikeSignupPage(fields) {
    const passwordFields = fields.filter((field) => field.type === 'password' && field.viewable);
    const hasConfirmPassword = passwordFields.some((field) => bitwardenPasswordFieldRole(field) === 'confirm');
    const hasNewPassword = passwordFields.some((field) => bitwardenPasswordFieldRole(field) === 'new');
    if (hasConfirmPassword || hasNewPassword) {
      return true;
    }

    return fields.some((field) => /(sign[ -]?up|create|register|join|new account)/.test(bitwardenFieldText(field)));
  }

  function bitwardenSuggestPageAction(document = window.document) {
    const pageDetails = bitwardenCollectPageDetails(document);
    const passwordFields = pageDetails.fields.filter((field) => field.type === 'password' && field.viewable);
    const hasCurrentPassword = passwordFields.some((field) => bitwardenPasswordFieldRole(field) === 'current');
    const hasNewPassword = passwordFields.some((field) => bitwardenPasswordFieldRole(field) === 'new');
    const hasConfirmPassword = passwordFields.some((field) => bitwardenPasswordFieldRole(field) === 'confirm');

    if (hasCurrentPassword && (hasNewPassword || hasConfirmPassword)) {
      return 'changePassword';
    }

    if (bitwardenLooksLikeSignupPage(pageDetails.fields)
      && bitwardenPreferredUsernameField(pageDetails.fields)
      && bitwardenPreferredSavePasswordField(pageDetails.fields)) {
      return 'saveLogin';
    }

    return 'fill';
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
    const usernameField = bitwardenPreferredUsernameField(pageDetails.fields);
    const passwordField = bitwardenPreferredSavePasswordField(pageDetails.fields);

    return bitwardenBuildRequest("saveLogin", {
      loginTitle: document.title || null,
      pageDetails,
      password: passwordField?.value || null,
      urlString: bitwardenCurrentURL(),
      username: usernameField?.value || null,
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

  function bitwardenShouldPresentActionPanel(nativeResponse) {
    const response = nativeResponse?.response;
    const trigger = response?.request?.requestContext?.trigger;
    return bitwardenNeedsActionPanel(response?.submissionAction) && trigger !== 'actionPanelPrimary';
  }

  function bitwardenActionPendingMessage(submissionAction) {
    switch (submissionAction) {
      case 'saveNewLogin':
        return 'Saving login to Bitwarden…';
      case 'updateExistingLogin':
        return 'Updating login in Bitwarden…';
      case 'updatePassword':
        return 'Updating password in Bitwarden…';
      case 'fill':
        return 'Filling login from Bitwarden…';
      default:
        return null;
    }
  }

  function bitwardenStatusTone(nativeResponse) {
    const response = nativeResponse?.response;
    const message = response?.userMessage;
    if (typeof message === 'string' && /no matching bitwarden login found/i.test(message)) {
      return 'warning';
    }
    switch (response?.submissionAction) {
      case 'fill':
      case 'saveNewLogin':
      case 'updateExistingLogin':
      case 'updatePassword':
      case 'generatePassword':
        return 'success';
      default:
        return 'info';
    }
  }

  function bitwardenFollowUpResponseForGeneratedPassword(document = window.document, generatedPassword = null) {
    if (typeof generatedPassword !== 'string' || generatedPassword.length === 0) {
      return null;
    }

    const suggestedAction = bitwardenSuggestPageAction(document);
    switch (suggestedAction) {
      case 'saveLogin':
        return {
          response: {
            submissionAction: 'saveNewLogin',
            userMessage: 'Save this login to Bitwarden.',
          },
        };
      case 'changePassword':
        return {
          response: {
            submissionAction: 'updatePassword',
            userMessage: 'Update the password for this Bitwarden login.',
          },
        };
      default:
        return null;
    }
  }

  function bitwardenPresentActionPanel(nativeResponse, document = window.document) {
    const response = nativeResponse?.response;
    if (!document?.body || !response || !bitwardenShouldPresentActionPanel(nativeResponse)) {
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
    primaryButton.onclick = async () => {
      const pendingMessage = bitwardenActionPendingMessage(response.submissionAction);
      if (typeof pendingMessage === 'string' && pendingMessage.length > 0) {
        bitwardenPresentStatusBanner(pendingMessage, document, { tone: 'progress' });
      }
      await bitwardenTriggerSubmissionAction(response.submissionAction);
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

  function bitwardenPresentStatusBanner(message, document = window.document, options = {}) {
    if (!document?.body || typeof message !== "string" || message.length === 0) {
      return null;
    }

    bitwardenRemoveStatusBanner(document);

    const banner = document.createElement('div');
    banner.dataset.bitwardenStatusBanner = 'true';
    banner.dataset.bitwardenStatusTone = options.tone || 'info';
    banner.role = 'status';
    banner.ariaLive = options.tone === 'warning' ? 'assertive' : 'polite';
    banner.textContent = message;
    banner.style.position = 'fixed';
    banner.style.left = '16px';
    banner.style.right = '16px';
    banner.style.bottom = '16px';
    banner.style.zIndex = '2147483647';
    banner.style.padding = '12px 16px';
    banner.style.borderRadius = '14px';
    banner.style.fontSize = '14px';
    banner.style.fontFamily = '-apple-system, BlinkMacSystemFont, sans-serif';
    banner.style.boxShadow = '0 10px 30px rgba(0, 0, 0, 0.2)';
    banner.style.border = '1px solid rgba(255, 255, 255, 0.12)';
    switch (banner.dataset.bitwardenStatusTone) {
      case 'success':
        banner.style.background = 'rgba(33, 118, 61, 0.96)';
        banner.style.color = '#fff';
        break;
      case 'warning':
        banner.style.background = 'rgba(176, 86, 0, 0.96)';
        banner.style.color = '#fff';
        break;
      case 'progress':
        banner.style.background = 'rgba(24, 84, 186, 0.96)';
        banner.style.color = '#fff';
        break;
      default:
        banner.style.background = 'rgba(28, 28, 30, 0.92)';
        banner.style.color = '#fff';
        break;
    }
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
      bitwardenPresentStatusBanner(response.userMessage, window.document, { tone: bitwardenStatusTone(nativeResponse) });
    }

    const followUpResponse = response.submissionAction === 'generatePassword'
      ? bitwardenFollowUpResponseForGeneratedPassword(window.document, response.generatedPassword)
      : null;

    bitwardenPresentActionPanel(followUpResponse || nativeResponse);

    bitwardenDispatchStatusEvent(nativeResponse);
    return nativeResponse;
  }

  async function bitwardenSendBuiltRequest(type, requestBuilder, requestContext = null) {
    const nativeResponse = await browser.runtime.sendMessage({
      type,
      request: requestBuilder().request,
      requestContext,
    });
    return bitwardenApplyNativeResponse(nativeResponse);
  }

  async function bitwardenTriggerSuggestedAction(document = window.document) {
    switch (bitwardenSuggestPageAction(document)) {
      case 'changePassword':
        return bitwardenSendBuiltRequest('bitwarden:change-password', bitwardenBuildChangePasswordRequest, {
          trigger: 'suggestedAction',
          submissionAction: 'updatePassword',
        });
      case 'saveLogin':
        return bitwardenSendBuiltRequest('bitwarden:save-login', bitwardenBuildSaveLoginRequest, {
          trigger: 'suggestedAction',
          submissionAction: 'saveNewLogin',
        });
      default:
        return bitwardenSendBuiltRequest('bitwarden:fill', bitwardenBuildFillRequest, {
          trigger: 'suggestedAction',
          submissionAction: 'fill',
        });
    }
  }

  async function bitwardenTriggerSubmissionAction(submissionAction) {
    switch (submissionAction) {
      case 'saveNewLogin':
      case 'updateExistingLogin':
        return bitwardenSendBuiltRequest('bitwarden:save-login', bitwardenBuildSaveLoginRequest, {
          trigger: 'actionPanelPrimary',
          submissionAction,
        });
      case 'updatePassword':
        return bitwardenSendBuiltRequest('bitwarden:change-password', bitwardenBuildChangePasswordRequest, {
          trigger: 'actionPanelPrimary',
          submissionAction,
        });
      case 'fill':
        return bitwardenSendBuiltRequest('bitwarden:fill', bitwardenBuildFillRequest, {
          trigger: 'actionPanelPrimary',
          submissionAction,
        });
      default:
        return null;
    }
  }

  window.bitwardenSafariWebExtension = {
    applyGeneratedPassword: bitwardenApplyGeneratedPassword,
    applyFillScript: bitwardenApplyFillScript,
    applyNativeResponse: bitwardenApplyNativeResponse,
    presentActionPanel: bitwardenPresentActionPanel,
    presentStatusBanner: bitwardenPresentStatusBanner,
    shouldPresentActionPanel: bitwardenShouldPresentActionPanel,
    buildRequest: bitwardenBuildRequest,
    buildChangePasswordRequest: bitwardenBuildChangePasswordRequest,
    buildFillRequest: bitwardenBuildFillRequest,
    buildGeneratePasswordRequest: bitwardenBuildGeneratePasswordRequest,
    buildSaveLoginRequest: bitwardenBuildSaveLoginRequest,
    buildSetupRequest: bitwardenBuildSetupRequest,
    collectPageDetails: bitwardenCollectPageDetails,
    suggestPageAction: bitwardenSuggestPageAction,
    triggerSuggestedAction: bitwardenTriggerSuggestedAction,
    triggerSubmissionAction: bitwardenTriggerSubmissionAction,
    generatePassword: () => bitwardenSendBuiltRequest("bitwarden:generate-password", bitwardenBuildGeneratePasswordRequest),
    requestFill: () => bitwardenSendBuiltRequest("bitwarden:fill", bitwardenBuildFillRequest),
    requestSaveLogin: () => bitwardenSendBuiltRequest("bitwarden:save-login", bitwardenBuildSaveLoginRequest),
    requestChangePassword: () => bitwardenSendBuiltRequest("bitwarden:change-password", bitwardenBuildChangePasswordRequest),
    requestSetup: () => bitwardenSendBuiltRequest("bitwarden:setup", bitwardenBuildSetupRequest),
  };
})();
