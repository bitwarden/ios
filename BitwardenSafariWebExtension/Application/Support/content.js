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
        text: bitwardenTrimmedValue(element.innerText || element.textContent),
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

  function bitwardenPreferredUsernameField(fields, options = {}) {
    const includeHiddenEmail = options.includeHiddenEmail || false;
    const preferredField = fields.find((field) => field.type === 'email' && field.viewable)
      || fields.find((field) => field.type === 'text' && field.viewable)
      || fields.find((field) => field.type === 'tel' && field.viewable)
      || null;

    if (preferredField || !includeHiddenEmail || !bitwardenCanUseHiddenEmailUsername(fields, options.document, options.forms)) {
      return preferredField;
    }

    return fields.find((field) => field.type === 'email')
      || null;
  }

  function bitwardenCanUseHiddenEmailUsername(fields, document = window.document, forms = {}) {
    const passwordFields = fields.filter((field) => field.type === 'password' && field.viewable);
    if (passwordFields.some((field) => {
      const role = bitwardenPasswordFieldRole(field);
      return role === 'new' || role === 'confirm';
    })) {
      return true;
    }

    return passwordFields.length > 0 && bitwardenLooksLikeAccountSetupPage(document, forms);
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

  function bitwardenSignupFieldText(field) {
    const supplementalText = field.viewable && /^submit$/i.test(field.type || '')
      ? [field.value, field.text]
      : [];

    return [bitwardenFieldText(field), ...supplementalText]
      .filter((value) => typeof value === 'string' && value.length > 0)
      .join(' ')
      .toLowerCase();
  }

  function bitwardenPageText(document = window.document) {
    return [document?.title, document?.location?.href, window?.location?.href]
      .filter((value) => typeof value === 'string' && value.length > 0)
      .join(' ')
      .toLowerCase();
  }

  function bitwardenFormsText(forms) {
    return Object.values(forms || {})
      .flatMap((form) => [form?.htmlAction, form?.htmlName, form?.htmlID])
      .filter((value) => typeof value === 'string' && value.length > 0)
      .join(' ')
      .toLowerCase();
  }

  function bitwardenRelevantSignupSignals(fields, forms, candidates = []) {
    const candidateFields = candidates.filter(Boolean);
    const candidateFormIDs = [...new Set(candidateFields.map((field) => field?.form).filter(Boolean))];
    if (candidateFields.length > 0 && candidateFormIDs.length === 0) {
      return {
        fields: fields.filter((field) => !field.form),
        forms: {},
      };
    }

    if (candidateFormIDs.length === 0) {
      return {
        fields,
        forms,
      };
    }

    return {
      fields: fields.filter((field) => candidateFormIDs.includes(field.form)),
      forms: Object.fromEntries(Object.entries(forms || {}).filter(([, form]) => candidateFormIDs.includes(form?.opid))),
    };
  }

  function bitwardenLooksLikeAccountSetupPage(document = window.document, forms = {}) {
    const accountSetupSource = [bitwardenFormsText(forms), bitwardenPageText(document)]
      .filter((value) => typeof value === 'string' && value.length > 0)
      .join(' ');
    return /(accept invitation|activate( your)? account|set password|complete( your)? account)/.test(accountSetupSource);
  }

  function bitwardenLooksLikePasswordResetPage(fields, document = window.document, forms = {}) {
    const passwordFields = fields.filter((field) => field.type === 'password' && field.viewable);
    const hasNewPassword = passwordFields.some((field) => bitwardenPasswordFieldRole(field) === 'new');
    const hasConfirmPassword = passwordFields.some((field) => bitwardenPasswordFieldRole(field) === 'confirm');
    if (!(hasNewPassword || hasConfirmPassword)) {
      return false;
    }

    const resetSource = [bitwardenFormsText(forms), bitwardenPageText(document)]
      .filter((value) => typeof value === 'string' && value.length > 0)
      .join(' ');
    return /(reset|forgot|recover).{0,20}password|password.{0,20}(reset|forgot|recover)/.test(resetSource);
  }

  function bitwardenLooksLikeSignupPage(fields, document = window.document, forms = {}, candidates = []) {
    const signupSignals = bitwardenRelevantSignupSignals(fields, forms, candidates);
    const passwordFields = signupSignals.fields.filter((field) => field.type === 'password' && field.viewable);
    const hasConfirmPassword = passwordFields.some((field) => bitwardenPasswordFieldRole(field) === 'confirm');
    const hasNewPassword = passwordFields.some((field) => bitwardenPasswordFieldRole(field) === 'new');
    if (hasConfirmPassword || hasNewPassword) {
      return true;
    }

    if (passwordFields.length > 0 && bitwardenLooksLikeAccountSetupPage(document, signupSignals.forms)) {
      return true;
    }

    if (signupSignals.fields.some((field) => /(sign[ -]?up|create( your)? account|register account|join bitwarden|new account)/.test(bitwardenSignupFieldText(field)))) {
      return true;
    }

    if (/(sign[ -]?up|create( your)? account|register account|join bitwarden|new account)/.test(bitwardenFormsText(signupSignals.forms))) {
      return true;
    }

    return /(sign[ -]?up|create( your)? account|register account|join bitwarden|new account)/.test(bitwardenPageText(document));
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

    if (bitwardenLooksLikePasswordResetPage(pageDetails.fields, document, pageDetails.forms)) {
      return 'changePassword';
    }

    const preferredUsernameField = bitwardenPreferredUsernameField(pageDetails.fields, {
      includeHiddenEmail: true,
      document,
      forms: pageDetails.forms,
    });
    const preferredSavePasswordField = bitwardenPreferredSavePasswordField(pageDetails.fields);

    if (bitwardenLooksLikeSignupPage(
      pageDetails.fields,
      document,
      pageDetails.forms,
      [preferredUsernameField, preferredSavePasswordField],
    )
      && preferredUsernameField
      && preferredSavePasswordField) {
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
    const usernameField = bitwardenPreferredUsernameField(pageDetails.fields, {
      includeHiddenEmail: true,
      document,
      forms: pageDetails.forms,
    });
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
    const explicitCurrentPasswordField = passwordFields.find((field) => bitwardenPasswordFieldRole(field) === 'current') || null;
    const resetPasswordFlow = bitwardenLooksLikePasswordResetPage(pageDetails.fields, document, pageDetails.forms);
    const currentPasswordField = explicitCurrentPasswordField || (resetPasswordFlow ? null : passwordFields.at(0) || null);
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
    const generatedPasswordFollowUp = response?.followUpType === 'generatedPassword';
    switch (response?.submissionAction) {
      case "saveNewLogin":
        return {
          eyebrow: generatedPasswordFollowUp ? 'Review generated password' : 'Review before saving',
          title: generatedPasswordFollowUp ? 'Save generated password' : 'Save login',
          subtitle: response.userMessage || (generatedPasswordFollowUp ? 'Save this generated password to Bitwarden.' : 'Save this login to Bitwarden.'),
          primaryLabel: "Save in Bitwarden",
          dismissLabel: "Not now",
          iconBackground: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 0.16)' : 'rgba(52, 199, 89, 0.16)',
          iconColor: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 1)' : 'rgba(36, 138, 61, 1)',
          eyebrowBackground: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 0.12)' : 'rgba(52, 199, 89, 0.12)',
          eyebrowColor: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 1)' : 'rgba(36, 138, 61, 1)',
          primaryBackground: generatedPasswordFollowUp ? 'rgba(137, 68, 171, 1)' : 'rgba(24, 122, 51, 1)',
          detailBackground: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 0.08)' : 'rgba(52, 199, 89, 0.08)',
          detailBorder: generatedPasswordFollowUp ? '1px solid rgba(175, 82, 222, 0.18)' : '1px solid rgba(52, 199, 89, 0.18)',
          detailLabelColor: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 1)' : 'rgba(36, 138, 61, 1)',
          dismissBackground: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 0.12)' : 'rgba(52, 199, 89, 0.12)',
          dismissColor: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 1)' : 'rgba(36, 138, 61, 1)',
          dismissBorder: generatedPasswordFollowUp ? '1px solid rgba(175, 82, 222, 0.18)' : '1px solid rgba(52, 199, 89, 0.18)',
        };
      case "updateExistingLogin":
        return {
          eyebrow: 'Review before updating',
          title: "Update login",
          subtitle: response.userMessage || "Update the existing Bitwarden login with these changes.",
          primaryLabel: "Update in Bitwarden",
          dismissLabel: "Not now",
          iconBackground: 'rgba(0, 122, 255, 0.14)',
          iconColor: 'rgba(0, 122, 255, 1)',
          eyebrowBackground: 'rgba(0, 122, 255, 0.12)',
          eyebrowColor: 'rgba(0, 122, 255, 1)',
          primaryBackground: 'rgba(0, 86, 214, 1)',
          detailBackground: 'rgba(0, 122, 255, 0.08)',
          detailBorder: '1px solid rgba(0, 122, 255, 0.18)',
          detailLabelColor: 'rgba(0, 122, 255, 1)',
          dismissBackground: 'rgba(0, 122, 255, 0.12)',
          dismissColor: 'rgba(0, 122, 255, 1)',
          dismissBorder: '1px solid rgba(0, 122, 255, 0.18)',
        };
      case "updatePassword":
        return {
          eyebrow: generatedPasswordFollowUp ? 'Review generated password' : 'Review before updating',
          title: generatedPasswordFollowUp ? 'Update with generated password' : 'Update password',
          subtitle: response.userMessage || (generatedPasswordFollowUp ? 'Update this Bitwarden login with the generated password.' : 'Update the password for this Bitwarden login.'),
          primaryLabel: "Update in Bitwarden",
          dismissLabel: "Not now",
          iconBackground: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 0.16)' : 'rgba(0, 122, 255, 0.14)',
          iconColor: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 1)' : 'rgba(0, 122, 255, 1)',
          eyebrowBackground: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 0.12)' : 'rgba(0, 122, 255, 0.12)',
          eyebrowColor: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 1)' : 'rgba(0, 122, 255, 1)',
          primaryBackground: generatedPasswordFollowUp ? 'rgba(137, 68, 171, 1)' : 'rgba(0, 86, 214, 1)',
          detailBackground: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 0.08)' : 'rgba(0, 122, 255, 0.08)',
          detailBorder: generatedPasswordFollowUp ? '1px solid rgba(175, 82, 222, 0.18)' : '1px solid rgba(0, 122, 255, 0.18)',
          detailLabelColor: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 1)' : 'rgba(0, 122, 255, 1)',
          dismissBackground: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 0.12)' : 'rgba(0, 122, 255, 0.12)',
          dismissColor: generatedPasswordFollowUp ? 'rgba(175, 82, 222, 1)' : 'rgba(0, 122, 255, 1)',
          dismissBorder: generatedPasswordFollowUp ? '1px solid rgba(175, 82, 222, 0.18)' : '1px solid rgba(0, 122, 255, 0.18)',
        };
      default:
        return null;
    }
  }

  function bitwardenActionPanelSite(response) {
    const urlString = bitwardenTrimmedValue(response?.request?.urlString);
    if (!urlString) {
      return null;
    }

    try {
      const parsed = new URL(urlString);
      return bitwardenTrimmedValue(parsed.host) || bitwardenTrimmedValue(parsed.hostname) || bitwardenTrimmedValue(urlString);
    } catch (_error) {
      const normalized = urlString
        .replace(/^[a-z]+:\/\//i, '')
        .split('/')[0]
        .split('?')[0]
        .split('#')[0]
        .split('@').pop()
        .trim();
      return bitwardenTrimmedValue(normalized) || bitwardenTrimmedValue(urlString);
    }
  }

  function bitwardenActionPanelUsername(response) {
    return bitwardenTrimmedValue(response?.request?.username)
      || bitwardenTrimmedValue(response?.matchedLogin?.username)
      || null;
  }

  function bitwardenActionPanelDetails(response) {
    const details = [];
    const site = bitwardenActionPanelSite(response);
    const username = bitwardenActionPanelUsername(response);
    const generatedPasswordFollowUp = response?.followUpType === 'generatedPassword';

    if (site) {
      details.push({
        key: 'site',
        label: 'Site',
        value: site,
      });
    }

    if (username) {
      details.push({
        key: 'username',
        label: 'Username',
        value: username,
      });
    }

    if (generatedPasswordFollowUp) {
      details.push({
        key: 'generated-password',
        label: 'Password',
        value: 'Generated just now',
      });
    }

    return details;
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
    const message = response?.userMessage || nativeResponse?.errorMessage;
    if ((!response || typeof response !== 'object')
      && typeof nativeResponse?.errorMessage === 'string'
      && nativeResponse.errorMessage.length > 0) {
      return 'warning';
    }
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

    const pageDetails = bitwardenCollectPageDetails(document);
    const suggestedAction = bitwardenSuggestPageAction(document);
    switch (suggestedAction) {
      case 'saveLogin': {
        const usernameField = bitwardenPreferredUsernameField(pageDetails.fields, {
          includeHiddenEmail: true,
          document,
          forms: pageDetails.forms,
        });
        return {
          response: {
            followUpType: 'generatedPassword',
            request: {
              kind: 'saveLogin',
              urlString: bitwardenCurrentURL(),
              username: usernameField?.value || null,
            },
            submissionAction: 'saveNewLogin',
            userMessage: 'Save this generated password to Bitwarden.',
          },
        };
      }
      case 'changePassword':
        return {
          response: {
            followUpType: 'generatedPassword',
            request: {
              kind: 'changePassword',
              urlString: bitwardenCurrentURL(),
            },
            submissionAction: 'updatePassword',
            userMessage: 'Update this Bitwarden login with the generated password.',
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

    const eyebrow = document.createElement('div');
    eyebrow.dataset.bitwardenActionEyebrow = 'true';
    eyebrow.textContent = content.eyebrow || '';

    const icon = document.createElement('div');
    icon.dataset.bitwardenActionIcon = 'true';
    icon.textContent = 'B';

    const title = document.createElement('div');
    title.dataset.bitwardenActionTitle = 'true';
    title.textContent = content.title;

    const textGroup = document.createElement('div');
    textGroup.dataset.bitwardenActionTextGroup = 'true';

    const header = document.createElement('div');
    header.dataset.bitwardenActionHeader = 'true';

    const subtitle = document.createElement('div');
    subtitle.dataset.bitwardenActionSubtitle = 'true';
    subtitle.textContent = content.subtitle;

    const detailRows = bitwardenActionPanelDetails(response);
    const details = document.createElement('div');
    details.dataset.bitwardenActionDetails = 'true';
    details.style.display = detailRows.length > 0 ? 'grid' : 'none';
    details.style.gridTemplateColumns = 'repeat(2, minmax(0, 1fr))';
    details.style.gap = '10px';
    details.style.marginTop = detailRows.length > 0 ? '14px' : '0';

    detailRows.forEach((detail) => {
      const row = document.createElement('div');
      row.dataset.bitwardenActionDetail = detail.key;
      if (detail.key === 'site') {
        row.dataset.bitwardenActionDetailSite = 'true';
      }
      if (detail.key === 'username') {
        row.dataset.bitwardenActionDetailUsername = 'true';
      }
      if (detail.key === 'generated-password') {
        row.dataset.bitwardenActionDetailGeneratedPassword = 'true';
      }
      row.style.padding = '12px';
      row.style.borderRadius = '14px';
      row.style.background = content.detailBackground || 'rgba(120, 120, 128, 0.08)';
      row.style.border = content.detailBorder || '1px solid rgba(60, 60, 67, 0.08)';

      const label = document.createElement('div');
      label.textContent = detail.label;
      label.style.fontSize = '12px';
      label.style.fontWeight = '600';
      label.style.color = content.detailLabelColor || 'rgba(60, 60, 67, 0.72)';
      label.style.marginBottom = '4px';

      const value = document.createElement('div');
      value.textContent = detail.value;
      value.style.fontSize = '14px';
      value.style.fontWeight = '600';
      value.style.color = '#111';
      value.style.wordBreak = 'break-word';

      row.appendChild(label);
      row.appendChild(value);
      details.appendChild(row);
    });

    const buttons = document.createElement('div');
    buttons.dataset.bitwardenActionButtons = 'true';
    buttons.style.display = 'flex';
    buttons.style.gap = '10px';
    buttons.style.marginTop = '16px';

    const primaryButton = document.createElement('button');
    primaryButton.dataset.bitwardenActionPrimary = 'true';
    primaryButton.textContent = content.primaryLabel;
    primaryButton.style.background = content.primaryBackground || 'rgba(0, 122, 255, 1)';
    primaryButton.style.color = '#fff';
    primaryButton.style.border = 'none';
    primaryButton.style.borderRadius = '12px';
    primaryButton.style.padding = '12px 16px';
    primaryButton.style.fontWeight = '600';
    primaryButton.style.flex = '1';
    primaryButton.disabled = false;
    primaryButton.onclick = async () => {
      if (primaryButton.disabled) {
        return;
      }
      primaryButton.disabled = true;
      dismissButton.disabled = true;
      const pendingMessage = bitwardenActionPendingMessage(response.submissionAction);
      if (typeof pendingMessage === 'string' && pendingMessage.length > 0) {
        bitwardenPresentStatusBanner(pendingMessage, document, { tone: 'progress' });
      }
      try {
        await bitwardenTriggerSubmissionAction(response.submissionAction);
        bitwardenDispatchActionEvent({ action: response.submissionAction, confirmed: true });
        if (typeof panel.remove === 'function') {
          panel.remove();
        }
      } catch (error) {
        const errorMessage = error && typeof error.message === 'string' && error.message.length > 0
          ? error.message
          : 'Couldn’t complete the Bitwarden action.';
        bitwardenPresentStatusBanner(errorMessage, document, { tone: 'warning' });
        primaryButton.disabled = false;
        dismissButton.disabled = false;
      }
    };
    const dismissButton = document.createElement('button');
    dismissButton.dataset.bitwardenActionDismiss = 'true';
    dismissButton.textContent = content.dismissLabel;
    dismissButton.style.background = content.dismissBackground || 'rgba(120, 120, 128, 0.12)';
    dismissButton.style.color = content.dismissColor || '#111';
    dismissButton.style.border = content.dismissBorder || 'none';
    dismissButton.style.borderRadius = '12px';
    dismissButton.style.padding = '12px 16px';
    dismissButton.style.fontWeight = '500';
    dismissButton.disabled = false;
    dismissButton.onclick = () => {
      bitwardenDispatchActionEvent({ action: response.submissionAction, confirmed: false });
      if (typeof panel.remove === 'function') {
        panel.remove();
      }
    };
    if (typeof panel.appendChild === 'function') {
      buttons.appendChild(primaryButton);
      buttons.appendChild(dismissButton);
      textGroup.appendChild(eyebrow);
      textGroup.appendChild(title);
      textGroup.appendChild(subtitle);
      header.appendChild(icon);
      header.appendChild(textGroup);
      panel.appendChild(header);
      panel.appendChild(details);
      panel.appendChild(buttons);
    }
    header.style.display = 'flex';
    header.style.alignItems = 'flex-start';
    header.style.gap = '12px';
    icon.style.width = '36px';
    icon.style.height = '36px';
    icon.style.borderRadius = '999px';
    icon.style.display = 'flex';
    icon.style.alignItems = 'center';
    icon.style.justifyContent = 'center';
    icon.style.fontSize = '16px';
    icon.style.fontWeight = '700';
    icon.style.background = content.iconBackground || 'rgba(0, 122, 255, 0.14)';
    icon.style.color = content.iconColor || 'rgba(0, 122, 255, 1)';
    icon.style.flexShrink = '0';
    textGroup.style.display = 'grid';
    textGroup.style.gap = '6px';
    eyebrow.style.display = 'inline-flex';
    eyebrow.style.alignSelf = 'flex-start';
    eyebrow.style.padding = '4px 10px';
    eyebrow.style.borderRadius = '999px';
    eyebrow.style.background = content.eyebrowBackground || 'rgba(60, 60, 67, 0.08)';
    eyebrow.style.color = content.eyebrowColor || 'rgba(60, 60, 67, 0.82)';
    eyebrow.style.fontSize = '12px';
    eyebrow.style.fontWeight = '600';
    title.style.fontSize = '20px';
    title.style.fontWeight = '700';
    title.style.lineHeight = '1.2';
    subtitle.style.color = 'rgba(60, 60, 67, 0.82)';
    subtitle.style.lineHeight = '1.35';
    panel.style.position = 'fixed';
    panel.style.top = '16px';
    panel.style.left = '16px';
    panel.style.right = '16px';
    panel.style.maxWidth = '420px';
    panel.style.marginLeft = 'auto';
    panel.style.marginRight = 'auto';
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
    const errorMessage = typeof nativeResponse?.errorMessage === 'string' ? nativeResponse.errorMessage : null;

    window.bitwardenSafariWebExtension.lastNativeResponse = nativeResponse;

    if ((!response || typeof response !== "object") && !errorMessage) {
      return nativeResponse;
    }

    if (errorMessage && (!response || typeof response !== "object")) {
      bitwardenPresentStatusBanner(errorMessage, window.document, { tone: bitwardenStatusTone(nativeResponse) });
      bitwardenRemoveActionPanel(window.document);
      bitwardenDispatchStatusEvent(nativeResponse);
      return nativeResponse;
    }

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

  function bitwardenBridgeFailureResponse(error) {
    return {
      response: null,
      errorMessage: error && typeof error.message === 'string' && error.message.length > 0
        ? error.message
        : 'Couldn’t reach Bitwarden in Safari.',
    };
  }

  async function bitwardenSendBuiltRequest(type, requestBuilder, requestContext = null, options = {}) {
    try {
      const nativeResponse = await browser.runtime.sendMessage({
        type,
        request: requestBuilder().request,
        requestContext,
      });
      if (options.rethrowBridgeFailure
        && (!nativeResponse?.response || typeof nativeResponse.response !== 'object')
        && typeof nativeResponse?.errorMessage === 'string'
        && nativeResponse.errorMessage.length > 0) {
        throw new Error(nativeResponse.errorMessage);
      }
      return bitwardenApplyNativeResponse(nativeResponse);
    } catch (error) {
      if (options.rethrowBridgeFailure) {
        throw error;
      }
      return bitwardenApplyNativeResponse(bitwardenBridgeFailureResponse(error));
    }
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
        }, {
          rethrowBridgeFailure: true,
        });
      case 'updatePassword':
        return bitwardenSendBuiltRequest('bitwarden:change-password', bitwardenBuildChangePasswordRequest, {
          trigger: 'actionPanelPrimary',
          submissionAction,
        }, {
          rethrowBridgeFailure: true,
        });
      case 'fill':
        return bitwardenSendBuiltRequest('bitwarden:fill', bitwardenBuildFillRequest, {
          trigger: 'actionPanelPrimary',
          submissionAction,
        }, {
          rethrowBridgeFailure: true,
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
