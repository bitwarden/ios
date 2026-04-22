(() => {
  function bitwardenBuildRequest(kind) {
    return {
      id: crypto.randomUUID(),
      request: { kind },
    };
  }

  async function bitwardenGeneratePassword() {
    return browser.runtime.sendMessage({ type: "bitwarden:generate-password" });
  }

  window.bitwardenSafariWebExtension = {
    buildRequest: bitwardenBuildRequest,
    generatePassword: bitwardenGeneratePassword,
  };
})();
