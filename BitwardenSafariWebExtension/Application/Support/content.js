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
    const oldPassword = passwordFields.at(0)?.value || null;
    const password = passwordFields.at(-1)?.value || null;

    return bitwardenBuildRequest("changePassword", {
      loginTitle: document.title || null,
      oldPassword,
      pageDetails,
      password,
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

  async function bitwardenSendBuiltRequest(type, requestBuilder) {
    return browser.runtime.sendMessage({
      type,
      request: requestBuilder().request,
    });
  }

  window.bitwardenSafariWebExtension = {
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
