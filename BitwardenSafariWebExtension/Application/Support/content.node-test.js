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

function createButton({ id, name, type = 'submit', textContent = '', value = '', visible = true }) {
  const element = createInput({ id, name, type, value, visible });
  element.textContent = textContent;
  element.innerText = textContent;
  return element;
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
          const findChild = (predicate) => {
            for (const child of this.children) {
              if (predicate(child)) {
                return child;
              }
              if (typeof child.querySelector === 'function') {
                const nested = child.querySelector(selector);
                if (nested) {
                  return nested;
                }
              }
            }
            return null;
          };
          if (selector === '[data-bitwarden-action-dismiss]') {
            return findChild((child) => child.dataset?.bitwardenActionDismiss === 'true');
          }
          if (selector === '[data-bitwarden-action-primary]') {
            return findChild((child) => child.dataset?.bitwardenActionPrimary === 'true');
          }
          if (selector === '[data-bitwarden-action-title]') {
            return findChild((child) => child.dataset?.bitwardenActionTitle === 'true');
          }
          if (selector === '[data-bitwarden-action-header]') {
            return findChild((child) => child.dataset?.bitwardenActionHeader === 'true');
          }
          if (selector === '[data-bitwarden-action-icon]') {
            return findChild((child) => child.dataset?.bitwardenActionIcon === 'true');
          }
          if (selector === '[data-bitwarden-action-text-group]') {
            return findChild((child) => child.dataset?.bitwardenActionTextGroup === 'true');
          }
          if (selector === '[data-bitwarden-action-eyebrow]') {
            return findChild((child) => child.dataset?.bitwardenActionEyebrow === 'true');
          }
          if (selector === '[data-bitwarden-action-subtitle]') {
            return findChild((child) => child.dataset?.bitwardenActionSubtitle === 'true');
          }
          if (selector === '[data-bitwarden-action-buttons]') {
            return findChild((child) => child.dataset?.bitwardenActionButtons === 'true');
          }
          if (selector === '[data-bitwarden-action-details]') {
            return findChild((child) => child.dataset?.bitwardenActionDetails === 'true');
          }
          if (selector === '[data-bitwarden-action-detail-site]') {
            return findChild((child) => child.dataset?.bitwardenActionDetailSite === 'true');
          }
          if (selector === '[data-bitwarden-action-detail-username]') {
            return findChild((child) => child.dataset?.bitwardenActionDetailUsername === 'true');
          }
          if (selector === '[data-bitwarden-action-detail-generated-password]') {
            return findChild((child) => child.dataset?.bitwardenActionDetailGeneratedPassword === 'true');
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
      request: {
        kind: 'saveLogin',
        urlString: 'https://vault.example.com/login',
        username: 'user@example.com',
      },
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
  const title = actionPanel.querySelector('[data-bitwarden-action-title]');
  const header = actionPanel.querySelector('[data-bitwarden-action-header]');
  const icon = actionPanel.querySelector('[data-bitwarden-action-icon]');
  const textGroup = actionPanel.querySelector('[data-bitwarden-action-text-group]');
  const eyebrow = actionPanel.querySelector('[data-bitwarden-action-eyebrow]');
  const subtitle = actionPanel.querySelector('[data-bitwarden-action-subtitle]');
  const details = actionPanel.querySelector('[data-bitwarden-action-details]');
  const siteDetail = actionPanel.querySelector('[data-bitwarden-action-detail-site]');
  const usernameDetail = actionPanel.querySelector('[data-bitwarden-action-detail-username]');
  const buttons = actionPanel.querySelector('[data-bitwarden-action-buttons]');
  assert.ok(title);
  assert.ok(header);
  assert.ok(icon);
  assert.ok(textGroup);
  assert.ok(eyebrow);
  assert.ok(subtitle);
  assert.ok(details);
  assert.ok(siteDetail);
  assert.ok(usernameDetail);
  assert.ok(buttons);
  assert.equal(eyebrow.textContent, 'Review before saving');
  assert.equal(icon.textContent, 'B');
  assert.equal(icon.style.background, 'rgba(52, 199, 89, 0.16)');
  assert.equal(icon.style.color, 'rgba(36, 138, 61, 1)');
  assert.equal(title.textContent, 'Save login');
  assert.equal(subtitle.textContent, 'Save this login to Bitwarden.');
  assert.equal(siteDetail.textContent, '');
  assert.equal(siteDetail.children.length, 2);
  assert.equal(siteDetail.children[0].textContent, 'Site');
  assert.equal(siteDetail.children[1].textContent, 'vault.example.com');
  assert.equal(usernameDetail.textContent, '');
  assert.equal(usernameDetail.children.length, 2);
  assert.equal(usernameDetail.children[0].textContent, 'Username');
  assert.equal(usernameDetail.children[1].textContent, 'user@example.com');
  assert.equal(siteDetail.style.background, 'rgba(52, 199, 89, 0.08)');
  assert.equal(siteDetail.style.border, '1px solid rgba(52, 199, 89, 0.18)');
  assert.equal(siteDetail.children[0].style.color, 'rgba(36, 138, 61, 1)');
  const primary = buttons.querySelector('[data-bitwarden-action-primary]');
  const dismiss = buttons.querySelector('[data-bitwarden-action-dismiss]');
  assert.equal(primary.textContent, 'Save in Bitwarden');
  assert.equal(dismiss.textContent, 'Not now');
  assert.equal(buttons.style.display, 'flex');
  assert.equal(eyebrow.style.background, 'rgba(52, 199, 89, 0.12)');
  assert.equal(eyebrow.style.color, 'rgba(36, 138, 61, 1)');
  assert.equal(primary.style.background, 'rgba(24, 122, 51, 1)');
  assert.equal(actionPanel.style.maxWidth, '420px');
  assert.equal(actionPanel.style.marginLeft, 'auto');
  assert.equal(actionPanel.style.marginRight, 'auto');
  assert.equal(primary.style.color, '#fff');
  assert.equal(dismiss.style.background, 'rgba(52, 199, 89, 0.12)');
  assert.equal(dismiss.style.color, 'rgba(36, 138, 61, 1)');
  assert.equal(dismiss.style.border, '1px solid rgba(52, 199, 89, 0.18)');
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
  const ctx = makeEnvironment([email, password, confirmPassword], {
    href: 'https://signup.example.com/register',
  });
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
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-eyebrow]').textContent, 'Review generated password');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-title]').textContent, 'Save generated password');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-icon]').style.background, 'rgba(175, 82, 222, 0.16)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-icon]').style.color, 'rgba(175, 82, 222, 1)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-eyebrow]').style.background, 'rgba(175, 82, 222, 0.12)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-eyebrow]').style.color, 'rgba(175, 82, 222, 1)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-primary]').style.background, 'rgba(137, 68, 171, 1)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-subtitle]').textContent, 'Save this generated password to Bitwarden.');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-primary]').textContent, 'Save in Bitwarden');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-site]').textContent, '');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-site]').children[0].textContent, 'Site');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-site]').children[1].textContent, 'signup.example.com');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-username]').textContent, '');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-username]').children[0].textContent, 'Username');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-username]').children[1].textContent, 'user@example.com');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-generated-password]').textContent, '');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-generated-password]').children[0].textContent, 'Password');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-generated-password]').children[1].textContent, 'Generated just now');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-site]').style.background, 'rgba(175, 82, 222, 0.08)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-site]').style.border, '1px solid rgba(175, 82, 222, 0.18)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-generated-password]').children[0].style.color, 'rgba(175, 82, 222, 1)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-dismiss]').style.background, 'rgba(175, 82, 222, 0.12)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-dismiss]').style.color, 'rgba(175, 82, 222, 1)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-dismiss]').style.border, '1px solid rgba(175, 82, 222, 0.18)');
}

async function testApplyGeneratedPassword_showsUpdatePasswordFollowUpPanel() {
  const currentPassword = createInput({ id: 'current-password', name: 'currentPassword', type: 'password', value: 'old-secret' });
  currentPassword.placeholder = 'Current password';
  const newPassword = createInput({ id: 'new-password', name: 'newPassword', type: 'password', value: '' });
  newPassword.placeholder = 'New password';
  const confirmPassword = createInput({ id: 'confirm-password', name: 'confirmPassword', type: 'password', value: '' });
  confirmPassword.placeholder = 'Confirm password';
  const ctx = makeEnvironment([currentPassword, newPassword, confirmPassword], {
    href: 'https://accounts.example.com/change-password',
  });
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'generatePassword',
      generatedPassword: 'generated-secret',
    },
  });

  const actionPanel = ctx.document.body.querySelector('[data-bitwarden-action-panel]');
  assert.ok(actionPanel);
  assert.equal(actionPanel.dataset.bitwardenActionKind, 'updatePassword');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-eyebrow]').textContent, 'Review generated password');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-title]').textContent, 'Update with generated password');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-subtitle]').textContent, 'Update this Bitwarden login with the generated password.');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-primary]').textContent, 'Update in Bitwarden');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-primary]').style.background, 'rgba(137, 68, 171, 1)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-site]').textContent, '');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-site]').children[0].textContent, 'Site');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-site]').children[1].textContent, 'accounts.example.com');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-generated-password]').textContent, '');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-generated-password]').children[0].textContent, 'Password');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-generated-password]').children[1].textContent, 'Generated just now');
}

async function testApplyUpdateExistingLogin_showsStructuredPanelCopy() {
  const email = createInput({ id: 'email', name: 'email', type: 'email', value: 'user@example.com' });
  const password = createInput({ id: 'password', name: 'password', type: 'password', value: 'secret' });
  const ctx = makeEnvironment([email, password]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      request: {
        kind: 'saveLogin',
        urlString: 'https://accounts.example.com/sign-in',
      },
      matchedLogin: {
        username: 'matched@example.com',
      },
      submissionAction: 'updateExistingLogin',
      userMessage: 'Update the existing Bitwarden login with these changes.',
    },
  });

  const actionPanel = ctx.document.body.querySelector('[data-bitwarden-action-panel]');
  assert.ok(actionPanel);
  assert.equal(actionPanel.dataset.bitwardenActionKind, 'updateExistingLogin');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-eyebrow]').textContent, 'Review before updating');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-title]').textContent, 'Update login');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-subtitle]').textContent, 'Update the existing Bitwarden login with these changes.');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-icon]').style.background, 'rgba(0, 122, 255, 0.14)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-icon]').style.color, 'rgba(0, 122, 255, 1)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-eyebrow]').style.background, 'rgba(0, 122, 255, 0.12)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-eyebrow]').style.color, 'rgba(0, 122, 255, 1)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-primary]').style.background, 'rgba(0, 86, 214, 1)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-site]').textContent, '');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-site]').children[0].textContent, 'Site');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-site]').children[1].textContent, 'accounts.example.com');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-username]').textContent, '');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-username]').children[0].textContent, 'Username');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-username]').children[1].textContent, 'matched@example.com');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-site]').style.background, 'rgba(0, 122, 255, 0.08)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-site]').style.border, '1px solid rgba(0, 122, 255, 0.18)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-username]').children[0].style.color, 'rgba(0, 122, 255, 1)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-dismiss]').style.background, 'rgba(0, 122, 255, 0.12)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-dismiss]').style.color, 'rgba(0, 122, 255, 1)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-dismiss]').style.border, '1px solid rgba(0, 122, 255, 0.18)');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-primary]').textContent, 'Update in Bitwarden');
}

async function testApplyUpdateExistingLogin_stripsSensitiveURLPartsFromSiteDetail() {
  const email = createInput({ id: 'email', name: 'email', type: 'email', value: 'user@example.com' });
  const password = createInput({ id: 'password', name: 'password', type: 'password', value: 'new-secret' });
  const ctx = makeEnvironment([email, password]);
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      request: {
        kind: 'saveLogin',
        urlString: 'https://user:pass@accounts.example.com/sign-in?token=abc#frag',
      },
      matchedLogin: {
        username: 'matched@example.com',
      },
      submissionAction: 'updateExistingLogin',
      userMessage: 'Update the existing Bitwarden login with these changes.',
    },
  });

  const actionPanel = ctx.document.body.querySelector('[data-bitwarden-action-panel]');
  assert.ok(actionPanel);
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-detail-site]').children[1].textContent, 'accounts.example.com');
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
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-title]').textContent, 'Update password');
  assert.equal(actionPanel.querySelector('[data-bitwarden-action-subtitle]').textContent, 'Update the password for this Bitwarden login.');

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
  const dismissEvent = ctx.window.dispatchedEvents.find((event) => event.type === 'bitwarden:safari-extension-action' && event.detail?.confirmed === false);
  assert.ok(dismissEvent);
  assert.equal(dismissEvent.detail.action, 'saveNewLogin');
  assert.equal(dismissEvent.detail.confirmed, false);
  assert.equal(ctx.document.body.querySelector('[data-bitwarden-action-panel]'), null);
}

function testBuildChangePasswordRequest_usesCurrentAndNewPasswordHeuristics() {
  const currentPassword = createInput({ id: 'current-password', name: 'currentPassword', type: 'password', value: 'old-secret' });
  currentPassword.placeholder = 'Current password';
  const newPassword = createInput({ id: 'new-password', name: 'newPassword', type: 'password', value: 'new-secret' });
  newPassword.placeholder = 'New password';
  const confirmPassword = createInput({ id: 'confirm-password', name: 'confirmPassword', type: 'password', value: 'confirm-secret' });
  confirmPassword.placeholder = 'Confirm password';

  let ctx = makeEnvironment([currentPassword, newPassword, confirmPassword]);
  let built = ctx.window.bitwardenSafariWebExtension.buildChangePasswordRequest();

  assert.equal(built.request.kind, 'changePassword');
  assert.equal(built.request.oldPassword, 'old-secret');
  assert.equal(built.request.password, 'new-secret');

  const resetEmail = createInput({ id: 'reset-email', name: 'email', type: 'email', value: 'user@example.com' });
  const resetPassword = createInput({ id: 'reset-password', name: 'newPassword', type: 'password', value: 'reset-secret' });
  resetPassword.placeholder = 'New password';
  const resetConfirm = createInput({ id: 'reset-confirm', name: 'confirmPassword', type: 'password', value: 'reset-secret' });
  resetConfirm.placeholder = 'Confirm password';

  ctx = makeEnvironment([resetEmail, resetPassword, resetConfirm], {
    title: 'Reset your password',
    href: 'https://example.com/reset-password',
  });
  built = ctx.window.bitwardenSafariWebExtension.buildChangePasswordRequest();

  assert.equal(built.request.kind, 'changePassword');
  assert.equal(built.request.oldPassword, null);
  assert.equal(built.request.password, 'reset-secret');
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

  let ctx = makeEnvironment([username, email, confirmPassword, password]);
  let built = ctx.window.bitwardenSafariWebExtension.buildSaveLoginRequest();

  assert.equal(built.request.kind, 'saveLogin');
  assert.equal(built.request.username, 'user@example.com');
  assert.equal(built.request.password, 'signup-secret');

  const hiddenEmail = createInput({ id: 'hidden-email', name: 'email', type: 'email', value: 'hidden-user@example.com', visible: false });
  const hiddenSignupPassword = createInput({ id: 'signup-password', name: 'password', type: 'password', value: 'hidden-signup-secret' });
  hiddenSignupPassword.placeholder = 'Create password';
  const hiddenSignupConfirm = createInput({ id: 'signup-confirm', name: 'confirmPassword', type: 'password', value: 'hidden-signup-secret' });
  hiddenSignupConfirm.placeholder = 'Confirm password';

  ctx = makeEnvironment([hiddenEmail, hiddenSignupPassword, hiddenSignupConfirm], {
    title: 'Create your account',
    href: 'https://example.com/account/create/password',
  });
  built = ctx.window.bitwardenSafariWebExtension.buildSaveLoginRequest();

  assert.equal(built.request.kind, 'saveLogin');
  assert.equal(built.request.username, 'hidden-user@example.com');
  assert.equal(built.request.password, 'hidden-signup-secret');

  const hiddenText = createInput({ id: 'hidden-referral', name: 'referralCode', type: 'text', value: 'invite-code', visible: false });
  ctx = makeEnvironment([hiddenText, hiddenSignupPassword, hiddenSignupConfirm], {
    title: 'Create your account',
    href: 'https://example.com/account/create/password',
  });
  built = ctx.window.bitwardenSafariWebExtension.buildSaveLoginRequest();

  assert.equal(built.request.username, null);

  const hiddenLoginEmail = createInput({ id: 'login-email-hidden', name: 'email', type: 'email', value: 'returning-user@example.com', visible: false });
  const hiddenLoginPassword = createInput({ id: 'login-password-visible', name: 'password', type: 'password', value: 'login-secret' });
  hiddenLoginPassword.placeholder = 'Password';
  ctx = makeEnvironment([hiddenLoginEmail, hiddenLoginPassword], {
    title: 'Sign in',
    href: 'https://example.com/login/password',
  });
  built = ctx.window.bitwardenSafariWebExtension.buildSaveLoginRequest();

  assert.equal(built.request.username, null);

  const inviteEmail = createInput({ id: 'invite-email-hidden', name: 'email', type: 'email', value: 'invited-user@example.com', visible: false });
  const invitePassword = createInput({ id: 'invite-password-visible', name: 'password', type: 'password', value: 'invite-secret' });
  invitePassword.placeholder = 'Password';
  ctx = makeEnvironment([inviteEmail, invitePassword], {
    title: 'Accept invitation',
    href: 'https://example.com/invite/accept',
  });
  built = ctx.window.bitwardenSafariWebExtension.buildSaveLoginRequest();

  assert.equal(built.request.username, 'invited-user@example.com');
  assert.equal(built.request.password, 'invite-secret');

  const activationEmail = createInput({ id: 'activation-email-hidden', name: 'email', type: 'email', value: 'member@example.com', visible: false });
  const activationPassword = createInput({ id: 'activation-password-visible', name: 'password', type: 'password', value: 'activation-secret' });
  activationPassword.placeholder = 'Password';
  ctx = makeEnvironment([activationEmail, activationPassword], {
    title: 'Activation required',
    href: 'https://example.com/activation/check',
  });
  built = ctx.window.bitwardenSafariWebExtension.buildSaveLoginRequest();

  assert.equal(built.request.username, null);

  const activateAccountEmail = createInput({ id: 'activate-account-email-hidden', name: 'email', type: 'email', value: 'activate-user@example.com', visible: false });
  const activateAccountPassword = createInput({ id: 'activate-account-password-visible', name: 'password', type: 'password', value: 'activate-secret' });
  activateAccountPassword.placeholder = 'Password';
  ctx = makeEnvironment([activateAccountEmail, activateAccountPassword], {
    title: 'Activate your account',
    href: 'https://example.com/account/activate',
  });
  built = ctx.window.bitwardenSafariWebExtension.buildSaveLoginRequest();

  assert.equal(built.request.username, 'activate-user@example.com');
  assert.equal(built.request.password, 'activate-secret');

  const completeAccountEmail = createInput({ id: 'complete-account-email-hidden', name: 'email', type: 'email', value: 'complete-user@example.com', visible: false });
  const completeAccountPassword = createInput({ id: 'complete-account-password-visible', name: 'password', type: 'password', value: 'complete-secret' });
  completeAccountPassword.placeholder = 'Password';
  ctx = makeEnvironment([completeAccountEmail, completeAccountPassword], {
    title: 'Complete your account',
    href: 'https://example.com/account/complete',
  });
  built = ctx.window.bitwardenSafariWebExtension.buildSaveLoginRequest();

  assert.equal(built.request.username, 'complete-user@example.com');
  assert.equal(built.request.password, 'complete-secret');
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

  const hiddenSignupEmail = createInput({ id: 'hidden-signup-email', name: 'email', type: 'email', value: 'hidden-user@example.com', visible: false });
  const hiddenSignupPassword = createInput({ id: 'hidden-signup-password', name: 'password', type: 'password', value: 'secret' });
  hiddenSignupPassword.placeholder = 'Create password';
  const hiddenSignupConfirm = createInput({ id: 'hidden-signup-confirm', name: 'confirmPassword', type: 'password', value: 'secret' });
  hiddenSignupConfirm.placeholder = 'Confirm password';
  ctx = makeEnvironment([hiddenSignupEmail, hiddenSignupPassword, hiddenSignupConfirm], {
    title: 'Create your account',
    href: 'https://example.com/account/create/password',
  });
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'saveLogin');

  const hiddenLoginEmail = createInput({ id: 'hidden-login-email', name: 'email', type: 'email', value: 'returning-user@example.com', visible: false });
  const hiddenLoginPassword = createInput({ id: 'hidden-login-password', name: 'password', type: 'password', value: 'secret' });
  hiddenLoginPassword.placeholder = 'Password';
  ctx = makeEnvironment([hiddenLoginEmail, hiddenLoginPassword], {
    title: 'Sign in',
    href: 'https://example.com/login/password',
  });
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'fill');

  const inviteEmail = createInput({ id: 'invite-email', name: 'email', type: 'email', value: 'invited-user@example.com', visible: false });
  const invitePassword = createInput({ id: 'invite-password', name: 'password', type: 'password', value: 'secret' });
  invitePassword.placeholder = 'Password';
  ctx = makeEnvironment([inviteEmail, invitePassword], {
    title: 'Accept invitation',
    href: 'https://example.com/invite/accept',
  });
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'saveLogin');

  const activationEmail = createInput({ id: 'activation-email', name: 'email', type: 'email', value: 'member@example.com', visible: false });
  const activationPassword = createInput({ id: 'activation-password', name: 'password', type: 'password', value: 'secret' });
  activationPassword.placeholder = 'Password';
  ctx = makeEnvironment([activationEmail, activationPassword], {
    title: 'Activation required',
    href: 'https://example.com/activation/check',
  });
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'fill');

  const activateAccountEmail = createInput({ id: 'activate-account-email', name: 'email', type: 'email', value: 'activate-user@example.com', visible: false });
  const activateAccountPassword = createInput({ id: 'activate-account-password', name: 'password', type: 'password', value: 'secret' });
  activateAccountPassword.placeholder = 'Password';
  ctx = makeEnvironment([activateAccountEmail, activateAccountPassword], {
    title: 'Activate your account',
    href: 'https://example.com/account/activate',
  });
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'saveLogin');

  const completeAccountEmail = createInput({ id: 'complete-account-email', name: 'email', type: 'email', value: 'complete-user@example.com', visible: false });
  const completeAccountPassword = createInput({ id: 'complete-account-password', name: 'password', type: 'password', value: 'secret' });
  completeAccountPassword.placeholder = 'Password';
  ctx = makeEnvironment([completeAccountEmail, completeAccountPassword], {
    title: 'Complete your account',
    href: 'https://example.com/account/complete',
  });
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

  const signupButton = createInput({ id: 'create-account', name: 'createAccount', type: 'submit', value: 'Create account' });
  ctx = makeEnvironment([loginUsername, loginPassword, signupButton]);
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'saveLogin');

  const signupButtonElement = createButton({ id: 'create-account-button', name: 'createAccountButton', textContent: 'Create account' });
  ctx = makeEnvironment([loginUsername, loginPassword, signupButtonElement]);
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'saveLogin');

  const accountCtaButton = createButton({ id: 'account-cta', name: 'accountCta', type: 'button', textContent: 'Create account' });
  ctx = makeEnvironment([loginUsername, loginPassword, accountCtaButton]);
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'fill');

  const hiddenSignupMarker = createInput({ id: 'flow', name: 'flow', type: 'hidden', value: 'Create account' });
  ctx = makeEnvironment([loginUsername, loginPassword, hiddenSignupMarker]);
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

  const loginForm = createForm({
    id: 'login-form',
    name: 'login',
    action: 'https://example.com/session',
  });
  const separateSignupForm = createForm({
    id: 'separate-signup-form',
    name: 'signup',
    action: 'https://example.com/users/sign_up',
  });
  loginUsername.form = loginForm;
  loginPassword.form = loginForm;
  signupButton.form = separateSignupForm;
  ctx = makeEnvironment([loginUsername, loginPassword, signupButton], {
    forms: [loginForm, separateSignupForm],
  });
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'fill');
  loginUsername.form = null;
  loginPassword.form = null;
  signupButton.form = null;

  const orphanSignupForm = createForm({
    id: 'orphan-signup-form',
    name: 'signup',
    action: 'https://example.com/users/sign_up',
  });
  signupButton.form = orphanSignupForm;
  ctx = makeEnvironment([loginUsername, loginPassword, signupButton], {
    forms: [orphanSignupForm],
  });
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'fill');
  signupButton.form = null;

  const resetEmail = createInput({ id: 'reset-email', name: 'email', type: 'email', value: 'user@example.com' });
  const resetPassword = createInput({ id: 'reset-password', name: 'newPassword', type: 'password', value: 'new-secret' });
  resetPassword.placeholder = 'New password';
  const resetConfirm = createInput({ id: 'reset-confirm', name: 'confirmPassword', type: 'password', value: 'new-secret' });
  resetConfirm.placeholder = 'Confirm password';
  ctx = makeEnvironment([resetEmail, resetPassword, resetConfirm], {
    title: 'Reset your password',
    href: 'https://example.com/reset-password',
  });
  assert.equal(ctx.window.bitwardenSafariWebExtension.suggestPageAction(), 'changePassword');

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

async function testRequestFill_sendMessageFailure_showsWarningBanner() {
  const username = createInput({ id: 'username', name: 'username', type: 'text', value: '' });
  const password = createInput({ id: 'password', name: 'password', type: 'password', value: '' });
  const ctx = makeEnvironment([username, password], {
    sendMessage: async () => {
      throw new Error('Native bridge unavailable');
    },
  });

  const response = await ctx.window.bitwardenSafariWebExtension.requestFill();

  const banner = ctx.document.body.querySelector('[data-bitwarden-status-banner]');
  assert.ok(banner);
  assert.equal(banner.textContent, 'Native bridge unavailable');
  assert.equal(banner.dataset.bitwardenStatusTone, 'warning');
  assert.equal(ctx.document.body.querySelector('[data-bitwarden-action-panel]'), null);
  assert.equal(response.errorMessage, 'Native bridge unavailable');
}

async function testActionPanelPrimaryErrorEnvelope_restoresPanelInteractivity() {
  const password = createInput({ id: 'password', name: 'password', type: 'password', value: 'secret' });
  const ctx = makeEnvironment([password], {
    sendMessage: async () => ({
      response: null,
      errorMessage: 'Native host missing',
    }),
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
  assert.equal(banner.textContent, 'Native host missing');
  assert.equal(banner.dataset.bitwardenStatusTone, 'warning');
  assert.equal(primaryButton.disabled, false);
  assert.equal(dismissButton.disabled, false);
  assert.ok(ctx.document.body.querySelector('[data-bitwarden-action-panel]'));
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
  await testRequestFill_sendMessageFailure_showsWarningBanner();
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
  await testApplyUpdateExistingLogin_showsStructuredPanelCopy();
  await testApplyUpdateExistingLogin_stripsSensitiveURLPartsFromSiteDetail();
  await testApplyGeneratedPasswordFailure_showsErrorBannerWithoutFollowUpPanel();
  await testActionPanelPrimaryErrorEnvelope_restoresPanelInteractivity();
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
