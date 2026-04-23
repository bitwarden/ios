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

function makeEnvironment(elements) {
  const dispatchedEvents = [];
  const document = {
    title: 'Example',
    location: { href: 'https://example.com/login' },
    documentElement: { dataset: {} },
    querySelectorAll(selector) {
      if (selector === 'form') return [];
      if (selector === 'input, select, textarea, button') return elements;
      if (selector === 'input[type="password"]') return elements.filter((e) => e.type === 'password');
      return [];
    },
    createEvent() {
      return { initEvent() {}, initKeyEvent() {} };
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
    location: { href: 'https://example.com/login' },
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
  const browser = { runtime: { sendMessage: async () => ({}) } };
  const context = {
    window,
    document,
    browser,
    crypto: { randomUUID: () => 'uuid-1' },
    console,
    setTimeout(fn) { fn(); return 0; },
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

async function testApplyGeneratedPassword() {
  const password = createInput({ id: 'password', name: 'password', type: 'password' });
  const ctx = makeEnvironment([password]);
  assert.equal(typeof ctx.window.bitwardenSafariWebExtension.applyNativeResponse, 'function');
  await ctx.window.bitwardenSafariWebExtension.applyNativeResponse({
    response: {
      submissionAction: 'generatePassword',
      generatedPassword: 'generated-secret',
    },
  });
  assert.equal(password.value, 'generated-secret');
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

(async () => {
  await testApplyGeneratedPassword();
  await testApplyFillScript();
  await testApplyStatusEvent();
  console.log('content node tests passed');
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
