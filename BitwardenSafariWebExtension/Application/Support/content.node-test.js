const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function createInput({ id, name, type, value = '', visible = true }) {
  const element = {
    id,
    name,
    type,
    value,
    disabled: false,
    readOnly: false,
    form: null,
    labels: [],
    className: '',
    dataset: {},
    style: {},
    ownerDocument: null,
    getAttribute(attr) {
      return this[attr] ?? null;
    },
    getBoundingClientRect() {
      return visible ? { width: 100, height: 20 } : { width: 0, height: 0 };
    },
    focus() {},
    blur() {},
    dispatchEvent() { return true; },
  };
  return element;
}

function createForm({ id, name, action, method = 'post' }) {
  return {
    id,
    name,
    action,
    method,
    dataset: {},
  };
}

function makeEnvironment(elements, options = {}) {
  const dispatchedEvents = [];
  const title = options.title || 'Example';
  const href = options.href || 'https://example.com/login';
  const forms = options.forms || [];
  const bannerContainer = {
    children: [],
    appendChild(node) {
      this.children.push(node);
      return node;
    },
    querySelector(selector) {
      if (selector === '[data-bitwarden-status-banner]') {
        return this.children.find((child) => child.dataset?.bitwardenStatusBanner === 'true') || null;
      }
      if (selector === '[data-bitwarden-action-panel]') {
        return this.children.find((child) => child.dataset?.bitwardenActionPanel === 'true') || null;
      }
      return null;
    },
  };
  const document = {
    title,
    location: { href },
    documentElement: { dataset: {} },
    body: bannerContainer,
    querySelectorAll(selector) {
      if (selector === 'form') return forms;
      if (selector === 'input, select, textarea, button') return elements;
      if (selector === 'input[type="password"]') return elements.filter((e) => e.type === 'password');
      return [];
    },
    createEvent() {
      return { initEvent() {}, initKeyEvent() {} };
    },
    createElement(tagName) {
      return {
        tagName,
        dataset: {},
        style: {},
        textContent: '',
        role: null,
        children: [],
        appendChild(child) {
          this.children.push(child);
          return child;
        },
        querySelector(selector) {
          if (selector === '[data-bitwarden-action-dismiss]') {
            return this.children.find((child) => child.dataset?.bitwardenActionDismiss === 'true') || null;
          }
          if (selector === '[data-bitwarden-action-primary]') {
            return this.children.find((child) => child.dataset?.bitwardenActionPrimary === 'true') || null;
          }
          return null;
        },
        remove() {
          bannerContainer.children = bannerContainer.children.filter((child) => child !== this);
        },
      };
    },
    elementFromPoint() {
      return null;
    },
    dispatchEvent(event) {
      dispatchedEvents.push(event);
      return true;
    },
  };
  elements.forEach((element) => { element.ownerDocument = document; });
  const window = {
    location: { href },
    document,
    dispatchedEvents,
    dispatchEvent(event) {
      dispatchedEvents.push(event);
      return true;
    },
    getComputedStyle() {
      return { display: 'block', visibility: 'visible' };
    },
  };
  const browser = {
    runtime: {
      sentMessages: [],
      sendMessage: async (message) => {
        browser.runtime.sentMessages.push(message);
        if (typeof options.sendMessage === 'function') {
          return options.sendMessage(message, browser);
        }
        return {};
      },
    },
  };
  const context = {
    window,
    document,
    browser,
    crypto: { randomUUID: () => 'uuid-1' },
    console,
    setTimeout() { return 0; },
    clearTimeout() {},
    Event: function Event(type) { this.type = type; },
    CustomEvent: function CustomEvent(type, init = {}) { this.type = type; this.detail = init.detail; },
  };
  vm.createContext(context);
  const source = fs.readFileSync('BitwardenSafariWebExtension/Application/Support/content.js', 'utf8');
  vm.runInContext(source, context);
  return context;
}

async function testApplyStatusEvent() {
  const password = createInput({ id: 'password', name: 'password', type: 'password' });
  const ctx = makeEnvironment([password]);
  const nativeResponse = {
    response: {
      submissionAction: 'updatePassword',
      userMessage: 'Password updated for this login.',
    },
  };
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse(nativeResponse);
  assert.equal(ctx.window.bitwardenSafariWebExtension.lastNativeResponse, nativeResponse);
  const statusEvent = ctx.window.dispatchedEvents.find((event) => event.type === 'bitwarden:safari-extension-response');
  assert.ok(statusEvent);
  assert.equal(statusEvent.detail.response.submissionAction, 'updatePassword');
  assert.equal(statusEvent.detail.response.userMessage, 'Password updated for this login.');
}

async function testApplyFillResponse_showsCompletionBannerWithoutPanel() {
  const username = createInput({ id: 'username', name: 'username', type: 'text', value: '' });
  const password = createInput({ id: 'password', name: 'password', type: 'password', value: '' });
  const ctx = makeEnvironment([username, password]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'fill',
      fillScriptJSON: JSON.stringify({
        script: [
          ['fill_by_opid', 'field__0', 'user@example.com'],
          ['fill_by_opid', 'field__1', 'secret'],
        ],
      }),
      userMessage: 'Filled user@example.com from Bitwarden.',
    },
  });

  const banner = ctx.document.body.querySelector('[data-bitwarden-status-banner]');
  assert.ok(banner);
  assert.equal(banner.textContent, 'Filled user@example.com from Bitwarden.');
  assert.equal(banner.dataset.bitwardenStatusTone, 'success');
  assert.equal(ctx.document.body.querySelector('[data-bitwarden-action-panel]'), null);
}

async function testApplyFillResponse_withoutUsername_usesSiteHostCopy() {
  const username = createInput({ id: 'username', name: 'username', type: 'text', value: '' });
  const password = createInput({ id: 'password', name: 'password', type: 'password', value: '' });
  const ctx = makeEnvironment([username, password]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'fill',
      fillScriptJSON: JSON.stringify({
        script: [
          ['fill_by_opid', 'field__0', 'user@example.com'],
          ['fill_by_opid', 'field__1', 'secret'],
        ],
      }),
      userMessage: 'Filled login for accounts.example.com from Bitwarden.',
    },
  });

  const banner = ctx.document.body.querySelector('[data-bitwarden-status-banner]');
  assert.ok(banner);
  assert.equal(banner.textContent, 'Filled login for accounts.example.com from Bitwarden.');
  assert.equal(banner.dataset.bitwardenStatusTone, 'success');
}

async function testApplyNoMatchFillMessage_showsBannerWithoutPanel() {
  const username = createInput({ id: 'username', name: 'username', type: 'text', value: '' });
  const password = createInput({ id: 'password', name: 'password', type: 'password', value: '' });
  const ctx = makeEnvironment([username, password]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'none',
      userMessage: 'No matching Bitwarden login found for this page.',
    },
  });

  const banner = ctx.document.body.querySelector('[data-bitwarden-status-banner]');
  assert.ok(banner);
  assert.equal(banner.textContent, 'No matching Bitwarden login found for this page.');
  assert.equal(banner.dataset.bitwardenStatusTone, 'warning');
  assert.equal(ctx.document.body.querySelector('[data-bitwarden-action-panel]'), null);
}

async function testApplyNativeErrorMessage_showsWarningBannerWithoutPanel() {
  const username = createInput({ id: 'username', name: 'username', type: 'text', value: '' });
  const password = createInput({ id: 'password', name: 'password', type: 'password', value: '' });
  const ctx = makeEnvironment([username, password]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    errorMessage: 'Native bridge failed.',
  });

  const banner = ctx.document.body.querySelector('[data-bitwarden-status-banner]');
  assert.ok(banner);
  assert.equal(banner.textContent, 'Native bridge failed.');
  assert.equal(banner.dataset.bitwardenStatusTone, 'warning');
  assert.equal(ctx.document.body.querySelector('[data-bitwarden-action-panel]'), null);
}

async function testApplyNativeErrorMessage_withResponse_prefersResponseHandling() {
  const username = createInput({ id: 'username', name: 'username', type: 'text', value: '' });
  const password = createInput({ id: 'password', name: 'password', type: 'password', value: '' });
  const ctx = makeEnvironment([username, password]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    errorMessage: 'Native bridge failed.',
    response: {
      submissionAction: 'fill',
      fillScriptJSON: JSON.stringify({
        script: [
          ['fill_by_opid', 'field__0', 'user@example.com'],
          ['fill_by_opid', 'field__1', 'secret'],
        ],
      }),
      userMessage: 'Filled user@example.com from Bitwarden.',
    },
  });

  assert.equal(username.value, 'user@example.com');
  assert.equal(password.value, 'secret');
  const banner = ctx.document.body.querySelector('[data-bitwarden-status-banner]');
  assert.ok(banner);
  assert.equal(banner.textContent, 'Filled user@example.com from Bitwarden.');
  assert.equal(banner.dataset.bitwardenStatusTone, 'success');
  assert.equal(ctx.document.body.querySelector('[data-bitwarden-action-panel]'), null);
}

async function testApplyStatusBanner() {
  const password = createInput({ id: 'password', name: 'password', type: 'password' });
  const ctx = makeEnvironment([password]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'saveNewLogin',
      userMessage: 'Save this login to Bitwarden.',
    },
  });

  const banner = ctx.document.body.querySelector('[data-bitwarden-status-banner]');
  assert.ok(banner);
  assert.equal(banner.textContent, 'Save this login to Bitwarden.');
  assert.equal(banner.role, 'status');

  const actionPanel = ctx.document.body.querySelector('[data-bitwarden-action-panel]');
  assert.ok(actionPanel);
  assert.equal(actionPanel.dataset.bitwardenActionKind, 'saveNewLogin');
  assert.equal(actionPanel.role, 'dialog');
  assert.match(actionPanel.textContent, /Save login/);
  assert.match(actionPanel.textContent, /Save this login to Bitwarden\./);
  assert.match(actionPanel.textContent, /Save in Bitwarden/);
  assert.match(actionPanel.textContent, /Not now/);
}

async function testApplyStatusBanner_doesNotReopenPanelForConfirmedAction() {
  const password = createInput({ id: 'password', name: 'password', type: 'password' });
  const ctx = makeEnvironment([password]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      request: {
        kind: 'saveLogin',
        requestContext: {
          trigger: 'actionPanelPrimary',
          submissionAction: 'saveNewLogin',
        },
      },
      submissionAction: 'saveNewLogin',
      userMessage: 'Save this login to Bitwarden.',
    },
  });

  const banner = ctx.document.body.querySelector('[data-bitwarden-status-banner]');
  assert.ok(banner);
  assert.equal(banner.textContent, 'Save this login to Bitwarden.');
  assert.equal(ctx.document.body.querySelector('[data-bitwarden-action-panel]'), null);
}

async function testApplyGeneratedPassword_showsSaveLoginFollowUpPanel() {
  const email = createInput({ id: 'email', name: 'email', type: 'email', value: 'user@example.com' });
  const password = createInput({ id: 'new-password', name: 'newPassword', type: 'password', value: '' });
  password.placeholder = 'New password';
  const confirmPassword = createInput({ id: 'confirm-password', name: 'confirmPassword', type: 'password', value: '' });
  confirmPassword.placeholder = 'Confirm password';
  const ctx = makeEnvironment([email, password, confirmPassword]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'generatePassword',
      generatedPassword: 'generated-secret',
      userMessage: 'Generated password with Bitwarden.',
    },
  });

  const banner = ctx.document.body.querySelector('[data-bitwarden-status-banner]');
  assert.ok(banner);
  assert.equal(banner.textContent, 'Generated password with Bitwarden.');
  assert.equal(banner.dataset.bitwardenStatusTone, 'success');

  const actionPanel = ctx.document.body.querySelector('[data-bitwarden-action-panel]');
  assert.ok(actionPanel);
  assert.equal(actionPanel.dataset.bitwardenActionKind, 'saveNewLogin');
  assert.match(actionPanel.textContent, /Save login/);
}

async function testApplyGeneratedPassword_showsUpdatePasswordFollowUpPanel() {
  const currentPassword = createInput({ id: 'current-password', name: 'currentPassword', type: 'password', value: 'old-secret' });
  currentPassword.placeholder = 'Current password';
  const newPassword = createInput({ id: 'new-password', name: 'newPassword', type: 'password', value: '' });
  newPassword.placeholder = 'New password';
  const confirmPassword = createInput({ id: 'confirm-password', name: 'confirmPassword', type: 'password', value: '' });
  confirmPassword.placeholder = 'Confirm password';
  const ctx = makeEnvironment([currentPassword, newPassword, confirmPassword]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'generatePassword',
      generatedPassword: 'generated-secret',
    },
  });

  const actionPanel = ctx.document.body.querySelector('[data-bitwarden-action-panel]');
  assert.ok(actionPanel);
  assert.equal(actionPanel.dataset.bitwardenActionKind, 'updatePassword');
  assert.match(actionPanel.textContent, /Update password/);
}

async function testApplyGeneratedPasswordFailure_showsErrorBannerWithoutFollowUpPanel() {
  const email = createInput({ id: 'email', name: 'email', type: 'email', value: 'user@example.com' });
  const password = createInput({ id: 'new-password', name: 'newPassword', type: 'password', value: '' });
  password.placeholder = 'New password';
  const confirmPassword = createInput({ id: 'confirm-password', name: 'confirmPassword', type: 'password', value: '' });
  confirmPassword.placeholder = 'Confirm password';
  const ctx = makeEnvironment([email, password, confirmPassword]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'none',
      userMessage: 'Couldn’t generate a password in Bitwarden.',
    },
  });

  const banner = ctx.document.body.querySelector('[data-bitwarden-status-banner]');
  assert.ok(banner);
  assert.equal(banner.textContent, 'Couldn’t generate a password in Bitwarden.');
  assert.equal(banner.dataset.bitwardenStatusTone, 'info');
  assert.equal(ctx.document.body.querySelector('[data-bitwarden-action-panel]'), null);
}

async function testActionPanelPrimaryDispatchesConfirmEvent() {
  const password = createInput({ id: 'password', name: 'password', type: 'password' });
  const ctx = makeEnvironment([password]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'saveNewLogin',
      userMessage: 'Save this login to Bitwarden.',
    },
  });

  const actionPanel = ctx.document.body.querySelector('[data-bitwarden-action-panel]');
  assert.ok(actionPanel);
  const primaryButton = actionPanel.querySelector('[data-bitwarden-action-primary]');
  assert.ok(primaryButton);
  await primaryButton.onclick();

  const confirmEvent = ctx.window.dispatchedEvents.find((event) => event.type === 'bitwarden:safari-extension-action');
  assert.ok(confirmEvent);
  assert.equal(confirmEvent.detail.action, 'saveNewLogin');
  assert.equal(confirmEvent.detail.confirmed, true);
  assert.equal(ctx.browser.runtime.sentMessages.at(-1).type, 'bitwarden:save-login');
  assert.equal(ctx.browser.runtime.sentMessages.at(-1).requestContext.trigger, 'actionPanelPrimary');
  assert.equal(ctx.browser.runtime.sentMessages.at(-1).requestContext.submissionAction, 'saveNewLogin');
  assert.equal(ctx.document.body.querySelector('[data-bitwarden-action-panel]'), null);
}

async function testActionPanelPrimaryShowsPendingBannerWhileSaving() {
  const password = createInput({ id: 'password', name: 'password', type: 'password', value: 'secret' });
  let resolveSendMessage;
  const sendMessagePromise = new Promise((resolve) => {
    resolveSendMessage = resolve;
  });
  const ctx = makeEnvironment([password], {
    sendMessage: () => sendMessagePromise,
  });
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'saveNewLogin',
      userMessage: 'Save this login to Bitwarden.',
    },
  });

  const actionPanel = ctx.document.body.querySelector('[data-bitwarden-action-panel]');
  assert.ok(actionPanel);
  const primaryButton = actionPanel.querySelector('[data-bitwarden-action-primary]');
  assert.ok(primaryButton);
  const dismissButton = actionPanel.querySelector('[data-bitwarden-action-dismiss]');
  assert.ok(dismissButton);

  const clickPromise = primaryButton.onclick();
  const pendingBanner = ctx.document.body.querySelector('[data-bitwarden-status-banner]');
  assert.ok(pendingBanner);
  assert.equal(pendingBanner.textContent, 'Saving login to Bitwarden…');
  assert.equal(pendingBanner.dataset.bitwardenStatusTone, 'progress');
  assert.equal(ctx.browser.runtime.sentMessages.at(-1).requestContext.submissionAction, 'saveNewLogin');
  assert.equal(primaryButton.disabled, true);
  assert.equal(dismissButton.disabled, true);

  await primaryButton.onclick();
  assert.equal(ctx.browser.runtime.sentMessages.length, 1);

  resolveSendMessage({ response: { submissionAction: 'saveNewLogin', userMessage: 'Saved login to Bitwarden.' } });
  await clickPromise;
  assert.equal(ctx.document.body.querySelector('[data-bitwarden-status-banner]').textContent, 'Saved login to Bitwarden.');
}

async function testUpdatePasswordPanelShowsSpecificTitle() {
  const currentPassword = createInput({ id: 'current-password', name: 'currentPassword', type: 'password', value: 'old-secret' });
  currentPassword.placeholder = 'Current password';
  const newPassword = createInput({ id: 'new-password', name: 'newPassword', type: 'password', value: 'new-secret' });
  newPassword.placeholder = 'New password';
  const confirmPassword = createInput({ id: 'confirm-password', name: 'confirmPassword', type: 'password', value: 'new-secret' });
  confirmPassword.placeholder = 'Confirm password';
  const ctx = makeEnvironment([currentPassword, newPassword, confirmPassword]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'updatePassword',
      userMessage: 'Update the password for this Bitwarden login.',
    },
  });

  const actionPanel = ctx.document.body.querySelector('[data-bitwarden-action-panel]');
  assert.ok(actionPanel);
  assert.match(actionPanel.textContent, /Update password/);
  assert.match(actionPanel.textContent, /Update the password for this Bitwarden login\./);

  const primaryButton = actionPanel.querySelector('[data-bitwarden-action-primary]');
  assert.ok(primaryButton);
  await primaryButton.onclick();
  assert.equal(ctx.browser.runtime.sentMessages.at(-1).type, 'bitwarden:change-password');
  assert.equal(ctx.browser.runtime.sentMessages.at(-1).requestContext.trigger, 'actionPanelPrimary');
  assert.equal(ctx.browser.runtime.sentMessages.at(-1).requestContext.submissionAction, 'updatePassword');
}

async function testActionPanelDismissRemovesPanel() {
  const password = createInput({ id: 'password', name: 'password', type: 'password' });
  const ctx = makeEnvironment([password]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'saveNewLogin',
      userMessage: 'Save this login to Bitwarden.',
    },
  });

  const actionPanel = ctx.document.body.querySelector('[data-bitwarden-action-panel]');
  assert.ok(actionPanel);
  const dismissButton = actionPanel.querySelector('[data-bitwarden-action-dismiss]');
  assert.ok(dismissButton);
  dismissButton.onclick();
  assert.equal(ctx.document.body.querySelector('[data-bitwarden-action-panel]'), null);
}

function testBuildChangePasswordRequest_usesCurrentAndNewPasswordHeuristics() {
  const currentPassword = createInput({ id: 'current-password', name: 'currentPassword', type: 'password', value: 'old-secret' });
  currentPassword.placeholder = 'Current password';
  const newPassword = createInput({ id: 'new-password', name: 'newPassword', type: 'password', value: 'new-secret' });
  newPassword.placeholder = 'New password';
  const confirmPassword = createInput({ id: 'confirm-password', name: 'confirmPassword', type: 'password', value: 'confirm-secret' });
  confirmPassword.placeholder = 'Confirm password';

  const ctx = makeEnvironment([currentPassword, newPassword, confirmPassword]);
  const built = ctx.window.bitwardenSafariWebExtension.buildChangePasswordRequest();

  assert.equal(built.request.kind, 'changePassword');
  assert.equal(built.request.oldPassword, 'old-secret');
  assert.equal(built.request.password, 'new-secret');
}

function testBuildSaveLoginRequest_prefersEmailAndIgnoresConfirmPassword() {
  const username = createInput({ id: 'username', name: 'username', type: 'text', value: 'display-name' });
  username.placeholder = 'Username';
  const email = createInput({ id: 'email', name: 'email', type: 'email', value: 'user@example.com' });
  email.placeholder = 'Email address';
  const confirmPassword = createInput({ id: 'confirm-password', name: 'confirmPassword', type: 'password', value: 'confirm-secret' });
  confirmPassword.placeholder = 'Confirm password';
  const password = createInput({ id: 'password', name: 'password', type: 'password', value: 'signup-secret' });
  password.placeholder = 'Create password';

  const ctx = makeEnvironment([username, email, confirmPassword, password]);
  const built = ctx.window.bitwardenSafariWebExtension.buildSaveLoginRequest();

  assert.equal(built.request.kind, 'saveLogin');
  assert.equal(built.request.username, 'user@example.com');
  assert.equal(built.request.password, 'signup-secret');
}

function testSuggestPageAction_detectsLoginSignupAndPasswordChange() {
  const loginUsername = createInput({ id: 'login-email', name: 'email', type: 'email', value: 'user@example.com' });
  loginUsername.placeholder = 'Email';
  const loginPassword = createInput({ id: 'login-password', name: 'password', type: 'password', value: 'secret' });
  loginPassword.placeholder = 'Password';
  let ctx = makeEnvironment([loginUsername, loginPassword]);
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'fill');

  const signupEmail = createInput({ id: 'signup-email', name: 'email', type: 'email', value: 'user@example.com' });
  const signupPassword = createInput({ id: 'signup-password', name: 'password', type: 'password', value: 'secret' });
  signupPassword.placeholder = 'Create password';
  const signupConfirm = createInput({ id: 'signup-confirm', name: 'confirmPassword', type: 'password', value: 'secret' });
  signupConfirm.placeholder = 'Confirm password';
  ctx = makeEnvironment([signupEmail, signupPassword, signupConfirm]);
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'saveLogin');

  ctx = makeEnvironment([loginUsername, loginPassword], {
    title: 'Create your account',
    href: 'https://example.com/account/create',
  });
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'saveLogin');

  const customDocument = {
    ...ctx.document,
    title: 'Create your account',
    location: { href: 'https://example.com/account/create' },
  };
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(customDocument), 'saveLogin');

  ctx = makeEnvironment([loginUsername, loginPassword], {
    title: 'Join meeting',
    href: 'https://example.com/join',
  });
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'fill');

  ctx = makeEnvironment([loginUsername, loginPassword], {
    title: 'Register device',
    href: 'https://example.com/register-device',
  });
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'fill');

  const signupForm = createForm({
    id: 'signup-form',
    name: 'signup',
    action: 'https://example.com/users/sign_up',
  });
  loginUsername.form = signupForm;
  loginPassword.form = signupForm;
  ctx = makeEnvironment([loginUsername, loginPassword], {
    forms: [signupForm],
  });
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'saveLogin');
  loginUsername.form = null;
  loginPassword.form = null;

  const currentPassword = createInput({ id: 'current-password', name: 'currentPassword', type: 'password', value: 'old-secret' });
  currentPassword.placeholder = 'Current password';
  const newPassword = createInput({ id: 'new-password', name: 'newPassword', type: 'password', value: 'new-secret' });
  newPassword.placeholder = 'New password';
  const confirmPassword = createInput({ id: 'confirm-password', name: 'confirmPassword', type: 'password', value: 'new-secret' });
  confirmPassword.placeholder = 'Confirm password';
  ctx = makeEnvironment([currentPassword, newPassword, confirmPassword]);
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'changePassword');
}

async function testTriggerSuggestedAction_sendsActionSpecificRequest() {
  const loginUsername = createInput({ id: 'login-email', name: 'email', type: 'email', value: 'user@example.com' });
  loginUsername.placeholder = 'Email';
  const loginPassword = createInput({ id: 'login-password', name: 'password', type: 'password', value: 'secret' });
  loginPassword.placeholder = 'Password';
  let ctx = makeEnvironment([loginUsername, loginPassword]);
  await ctx.window.bitwardenSafariWebExtension.triggerSuggestedAction();
  assert.equal(ctx.browser.runtime.sentMessages.at(-1).type, 'bitwarden:fill');
  assert.equal(ctx.browser.runtime.sentMessages.at(-1).requestContext.trigger, 'suggestedAction');

  const signupEmail = createInput({ id: 'signup-email', name: 'email', type: 'email', value: 'user@example.com' });
  const signupPassword = createInput({ id: 'signup-password', name: 'password', type: 'password', value: 'secret' });
  signupPassword.placeholder = 'Create password';
  const signupConfirm = createInput({ id: 'signup-confirm', name: 'confirmPassword', type: 'password', value: 'secret' });
  signupConfirm.placeholder = 'Confirm password';
  ctx = makeEnvironment([signupEmail, signupPassword, signupConfirm]);
  await ctx.window.bitwardenSafariWebExtension.triggerSuggestedAction();
  assert.equal(ctx.browser.runtime.sentMessages.at(-1).type, 'bitwarden:save-login');

  const currentPassword = createInput({ id: 'current-password', name: 'currentPassword', type: 'password', value: 'old-secret' });
  currentPassword.placeholder = 'Current password';
  const newPassword = createInput({ id: 'new-password', name: 'newPassword', type: 'password', value: 'new-secret' });
  newPassword.placeholder = 'New password';
  const confirmPassword = createInput({ id: 'confirm-password', name: 'confirmPassword', type: 'password', value: 'new-secret' });
  confirmPassword.placeholder = 'Confirm password';
  ctx = makeEnvironment([currentPassword, newPassword, confirmPassword]);
  await ctx.window.bitwardenSafariWebExtension.triggerSuggestedAction();
  assert.equal(ctx.browser.runtime.sentMessages.at(-1).type, 'bitwarden:change-password');
}

async function testApplyGeneratedPassword() {
  const password = createInput({ id: 'password', name: 'password', type: 'password' });
  const confirmPassword = createInput({ id: 'confirm-password', name: 'confirm-password', type: 'password' });
  const ctx = makeEnvironment([password, confirmPassword]);
  assert.equal(typeof ctx.window.bitwardenSafariWebExtension.applyNativeResponse, 'function');
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'generatePassword',
      generatedPassword: 'generated-secret',
    },
  });
  assert.equal(password.value, 'generated-secret');
  assert.equal(confirmPassword.value, 'generated-secret');
}

async function testApplyFillScript() {
  const username = createInput({ id: 'username', name: 'username', type: 'text' });
  const password = createInput({ id: 'password', name: 'password', type: 'password' });
  const ctx = makeEnvironment([username, password]);
  const fillScriptJSON = JSON.stringify({
    script: [
      ['fill_by_opid', 'field__0', 'user@example.com'],
      ['fill_by_opid', 'field__1', 'secret'],
    ],
  });
  assert.equal(typeof ctx.window.bitwardenSafariWebExtension.applyNativeResponse, 'function');
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'fill',
      fillScriptJSON,
    },
  });
  assert.equal(username.value, 'user@example.com');
  assert.equal(password.value, 'secret');
}

async function testActionPanelPrimaryFailure_restoresPanelInteractivity() {
  const password = createInput({ id: 'password', name: 'password', type: 'password', value: 'secret' });
  const ctx = makeEnvironment([password], {
    sendMessage: async () => {
      throw new Error('Bridge request failed');
    },
  });
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'saveNewLogin',
      userMessage: 'Save this login to Bitwarden.',
    },
  });

  const actionPanel = ctx.document.body.querySelector('[data-bitwarden-action-panel]');
  assert.ok(actionPanel);
  const primaryButton = actionPanel.querySelector('[data-bitwarden-action-primary]');
  const dismissButton = actionPanel.querySelector('[data-bitwarden-action-dismiss]');

  await primaryButton.onclick();

  const banner = ctx.document.body.querySelector('[data-bitwarden-status-banner]');
  assert.ok(banner);
  assert.equal(banner.textContent, 'Bridge request failed');
  assert.equal(banner.dataset.bitwardenStatusTone, 'warning');
  assert.equal(primaryButton.disabled, false);
  assert.equal(dismissButton.disabled, false);
  assert.ok(ctx.document.body.querySelector('[data-bitwarden-action-panel]'));
}

(async () => {
  testBuildChangePasswordRequest_usesCurrentAndNewPasswordHeuristics();
  testBuildSaveLoginRequest_prefersEmailAndIgnoresConfirmPassword();
  testSuggestPageAction_detectsLoginSignupAndPasswordChange();
  await testTriggerSuggestedAction_sendsActionSpecificRequest();
  await testApplyGeneratedPassword();
  await testApplyFillScript();
  await testApplyStatusEvent();
  await testApplyFillResponse_showsCompletionBannerWithoutPanel();
  await testApplyFillResponse_withoutUsername_usesSiteHostCopy();
  await testApplyNoMatchFillMessage_showsBannerWithoutPanel();
  await testApplyNativeErrorMessage_showsWarningBannerWithoutPanel();
  await testApplyNativeErrorMessage_withResponse_prefersResponseHandling();
  await testApplyStatusBanner();
  await testApplyStatusBanner_doesNotReopenPanelForConfirmedAction();
  await testApplyGeneratedPassword_showsSaveLoginFollowUpPanel();
  await testApplyGeneratedPassword_showsUpdatePasswordFollowUpPanel();
  await testApplyGeneratedPasswordFailure_showsErrorBannerWithoutFollowUpPanel();
  await testActionPanelPrimaryDispatchesConfirmEvent();
  await testActionPanelPrimaryShowsPendingBannerWhileSaving();
  await testActionPanelPrimaryFailure_restoresPanelInteractivity();
  await testUpdatePasswordPanelShowsSpecificTitle();
  await testActionPanelDismissRemovesPanel();
  console.log('content node tests passed');
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
