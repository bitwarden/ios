const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function makeEnvironment(options = {}) {
  const listeners = { onInstalled: null, onMessage: null };
  const browser = {
    runtime: {
      sendNativeMessage: async (name, payload) => {
        if (typeof options.sendNativeMessage === 'function') {
          return options.sendNativeMessage(name, payload);
        }
        return { message: JSON.stringify({ id: 'uuid-1', response: { submissionAction: 'none' } }) };
      },
      onInstalled: {
        addListener(listener) {
          listeners.onInstalled = listener;
        },
      },
      onMessage: {
        addListener(listener) {
          listeners.onMessage = listener;
        },
      },
    },
  };

  const context = {
    browser,
    crypto: { randomUUID: () => 'uuid-1' },
    console,
    Promise,
  };

  vm.createContext(context);
  const source = fs.readFileSync('BitwardenSafariWebExtension/Application/Support/background.js', 'utf8');
  vm.runInContext(source, context);
  return { context, browser, listeners };
}

async function testOnMessage_nativeFailure_returnsErrorEnvelope() {
  const { listeners } = makeEnvironment({
    sendNativeMessage: async () => {
      throw new Error('Native host missing');
    },
  });

  const response = await listeners.onMessage({
    type: 'bitwarden:fill',
    request: { kind: 'fill' },
  });

  assert.equal(response.id, 'uuid-1');
  assert.equal(response.response, null);
  assert.equal(response.errorMessage, 'Native host missing');
}

async function testOnMessage_invalidNativePayload_returnsParseErrorEnvelope() {
  const { listeners } = makeEnvironment({
    sendNativeMessage: async () => ({ message: '{not-json' }),
  });

  const response = await listeners.onMessage({
    type: 'bitwarden:fill',
    request: { kind: 'fill' },
  });

  assert.equal(response.id, null);
  assert.equal(response.response, null);
  assert.equal(response.errorMessage, 'Invalid native response payload');
}

async function testOnMessage_nativeStringPayload_parsesBridgeResponse() {
  const { listeners } = makeEnvironment({
    sendNativeMessage: async () => JSON.stringify({
      id: 'req-string',
      response: { submissionAction: 'fill' },
      errorMessage: null,
    }),
  });

  const response = await listeners.onMessage({
    type: 'bitwarden:fill',
    request: { kind: 'fill' },
  });

  assert.equal(response.id, 'req-string');
  assert.equal(response.response.submissionAction, 'fill');
  assert.equal(response.errorMessage, null);
}

(async () => {
  await testOnMessage_nativeFailure_returnsErrorEnvelope();
  await testOnMessage_invalidNativePayload_returnsParseErrorEnvelope();
  await testOnMessage_nativeStringPayload_parsesBridgeResponse();
  console.log('background node tests passed');
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
