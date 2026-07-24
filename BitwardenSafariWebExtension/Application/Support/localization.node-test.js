const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const supportDir = 'BitwardenSafariWebExtension/Application/Support';

function readJson(relativePath) {
  return JSON.parse(fs.readFileSync(path.join(supportDir, relativePath), 'utf8'));
}

function readText(relativePath) {
  return fs.readFileSync(path.join(supportDir, relativePath), 'utf8');
}

function testManifestUsesLocalizedMessages() {
  const manifest = readJson('manifest.json');
  assert.equal(manifest.default_locale, 'en');
  assert.equal(manifest.name, '__MSG_extensionName__');
  assert.equal(manifest.description, '__MSG_extensionDescription__');
}

function testJapaneseMessagesExist() {
  const messages = readJson('_locales/ja/messages.json');
  assert.equal(messages.extensionName.message, 'Bitwarden Safari機能拡張');
  assert.equal(messages.extensionDescription.message, 'iOS/iPadOS用のBitwarden Safari Web拡張機能です。');
}

function testEnglishFallbackMessagesExist() {
  const messages = readJson('_locales/en/messages.json');
  assert.equal(messages.extensionName.message, 'Bitwarden Safari');
  assert.equal(messages.extensionDescription.message, 'Bitwarden Safari Web Extension for iOS and iPadOS.');
}

function testInfoPlistJapaneseStringsExist() {
  const strings = readText('ja.lproj/InfoPlist.strings');
  assert.match(strings, /"CFBundleDisplayName"\s*=\s*"Bitwarden Safari機能拡張";/);
  assert.match(strings, /"CFBundleName"\s*=\s*"Bitwarden Safari Web拡張機能";/);
}

function testContentScriptIsInjectedOnWebPages() {
  const manifest = readJson('manifest.json');
  const contentScript = manifest.content_scripts?.find((entry) => entry.js?.includes('content.js'));
  assert.ok(contentScript, 'manifest must declare content.js as a content script');
  assert.deepEqual(contentScript.matches, ['<all_urls>']);
  assert.equal(contentScript.run_at, 'document_idle');
  assert.equal(contentScript.all_frames, true);
}

function testLocalizedResourcesAreInExtensionTarget() {
  const project = fs.readFileSync('Bitwarden.xcodeproj/project.pbxproj', 'utf8');
  assert.match(project, /_locales in Resources/);
  assert.match(project, /ja\.lproj in Resources/);
}

testManifestUsesLocalizedMessages();
testJapaneseMessagesExist();
testEnglishFallbackMessagesExist();
testInfoPlistJapaneseStringsExist();
testContentScriptIsInjectedOnWebPages();
testLocalizedResourcesAreInExtensionTarget();

console.log('localization node tests passed');
