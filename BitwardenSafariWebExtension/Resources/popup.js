// popup.js - Handles UI state and messaging with SafariWebExtensionHandler.swift

// --- View Management ---
const views = {
    locked: document.getElementById('locked-view'),
    unlocked: document.getElementById('unlocked-view'),
    details: document.getElementById('details-view')
};

function showView(viewId) {
    Object.values(views).forEach(v => v.classList.add('hidden'));
    if (views[viewId]) {
        views[viewId].classList.remove('hidden');
    }
}

// --- Icons (Matching Bitwarden App) ---
const ICONS = {
    login: '<svg viewBox="0 0 512 512"><path fill="currentColor" d="M256 0L24 65.5v281l232 165.5 232-165.5V65.5L256 0zM192 192v64h128v-64h-128zm0 128v64h128v-64h-128z"/></svg>',
    card: '<svg viewBox="0 0 512 512"><path fill="currentColor" d="M480 80H32C14.33 80 0 94.33 0 112v288c0 17.67 14.33 32 32 32h448c17.67 0 32-14.33 32-32V112c0-17.67-14.33-32-32-32zM96 352H64v-32h32v32zm0-64H64v-32h32v32zm0-64H64v-32h32v32zm384 128H160v-32h320v32zm0-64H160v-32h320v32zm0-64H160v-32h320v32z"/></svg>',
    identity: '<svg viewBox="0 0 512 512"><path fill="currentColor" d="M384 128h-32V96c0-17.67-14.33-32-32-32H96C78.33 64 64 78.33 64 96v256c0 17.67 14.33 32 32 32h32v32c0 17.67 14.33 32 32 32h224c17.67 0 32-14.33 32-32V160c0-17.67-14.33-32-32-32zm-64 224H160v-64h160v64zm0-96H160v-64h160v64z"/></svg>',
    copy: '<svg viewBox="0 0 448 512"><path fill="currentColor" d="M384 336H192c-8.8 0-16-7.2-16-16V64c0-8.8 7.2-16 16-16h140.1L400 115.9V320c0 8.8-7.2 16-16 16zM192 0C156.7 0 128 28.7 128 64v256c0 35.3 28.7 64 64 64h192c35.3 0 64-28.7 64-64V115.9c0-12.7-5.1-24.9-14.1-33.9L362.1 14.1C353.1 5.1 340.9 0 328.1 0H192zM80 128H64C28.7 128 0 156.7 0 192v256c0 35.3 28.7 64 64 64h192c35.3 0 64-28.7 64-64v-16h-48v16c0 8.8-7.2 16-16 16H64c-8.8 0-16-7.2-16-16V192c0-8.8 7.2-16 16-16h16v-48z"/></svg>',
    chevronRight: '<svg viewBox="0 0 256 512"><path fill="currentColor" d="M224.3 273l-136 136c-9.4 9.4-24.6 9.4-33.9 0l-22.6-22.6c-9.4-9.4-9.4-24.6 0-33.9l96.4-96.4-96.4-96.4c-9.4-9.4-9.4-24.6 0-33.9L54.3 103c9.4-9.4 24.6-9.4 33.9 0l136 136c9.5 9.4 9.5 24.6.1 34z"/></svg>',
    check: '<svg viewBox="0 0 512 512"><path fill="currentColor" d="M173.898 439.404l-166.4-166.4c-9.997-9.997-9.997-26.206 0-36.204l36.203-36.204c9.997-9.998 26.207-9.998 36.204 0L192 312.69 432.095 72.596c9.997-9.997 26.207-9.997 36.204 0l36.203 36.204c9.997 9.997 9.997 26.206 0 36.204l-294.4 294.401c-9.998 9.997-26.207 9.997-36.204-.001z"/></svg>'
};

// --- State ---
let currentItems = [];

// --- Messaging ---
function sendMessage(message) {
    return new Promise((resolve, reject) => {
        // Send message to background script which proxies to native app
        browser.runtime.sendMessage(message).then(response => {
            resolve(response);
        }).catch(err => {
            console.error("Messaging Error:", err);
            reject(err);
        });
    });
}

// --- Initialization ---
document.addEventListener('DOMContentLoaded', () => {
    checkVaultStatus();
});

function checkVaultStatus() {
    sendMessage({ type: "vaultStatus" }).then(response => {
        if (response.status === "locked" || response.status === "unauthenticated") {
            showView('locked');
        } else if (response.status === "unlocked") {
            loadSuggestions();
        } else {
            console.error("Unknown status:", response.status);
            showView('locked');
        }
    }).catch(err => {
        document.getElementById('unlock-error-text').innerText = "Failed to connect to Bitwarden app.";
    });
}

// --- Locked View Logic ---
const btnBiometricUnlock = document.getElementById('btn-biometric-unlock');
const btnPasswordUnlock = document.getElementById('btn-password-unlock');
const inputMasterPassword = document.getElementById('input-master-password');
const passwordFallbackContainer = document.getElementById('password-fallback-container');
const unlockErrorText = document.getElementById('unlock-error-text');

btnBiometricUnlock.addEventListener('click', () => {
    unlockErrorText.innerText = "";
    sendMessage({ type: "unlock" }).then(response => {
        if (response.status === "unlocked") {
            loadSuggestions();
        } else {
            // Biometrics failed or unavailable, show password fallback
            passwordFallbackContainer.classList.remove('hidden');
            inputMasterPassword.focus();
        }
    }).catch(err => {
        passwordFallbackContainer.classList.remove('hidden');
    });
});

btnPasswordUnlock.addEventListener('click', () => {
    const password = inputMasterPassword.value;
    if (!password) {
        unlockErrorText.innerText = "Please enter your Master Password.";
        return;
    }

    unlockErrorText.innerText = "";
    btnPasswordUnlock.disabled = true;

    sendMessage({ type: "unlockWithPassword", password: password }).then(response => {
        btnPasswordUnlock.disabled = false;
        if (response.status === "unlocked") {
            inputMasterPassword.value = "";
            loadSuggestions();
        } else {
            unlockErrorText.innerText = response.error || "Incorrect Master Password.";
        }
    }).catch(err => {
        btnPasswordUnlock.disabled = false;
        unlockErrorText.innerText = "Communication error.";
    });
});

inputMasterPassword.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        btnPasswordUnlock.click();
    }
});

// --- Unlocked (Suggestions) Logic ---
const btnLock = document.getElementById('btn-lock');
btnLock.addEventListener('click', () => {
    // For now, locking just resets the view locally as we don't have a 'lock' message sent to native
    // However realistically this button should lock the vault natively.
    showView('locked');
});

function loadSuggestions() {
    showView('unlocked');

    // Get current active tab URL to send to native app
    browser.tabs.query({ active: true, currentWindow: true }).then(tabs => {
        const url = tabs[0] ? tabs[0].url : "";

        sendMessage({ type: "getItems", url: url }).then(response => {
            if (response.error) {
                document.getElementById('items-error-text').innerText = response.error;
            } else {
                renderSuggestions(response.items || []);
            }
        }).catch(err => {
            document.getElementById('items-error-text').innerText = "Failed to fetch items.";
        });
    });
}

function renderSuggestions(items) {
    currentItems = items;
    const list = document.getElementById('suggestions-list');
    const noSuggestions = document.getElementById('no-suggestions-text');

    // Clear old items (keep empty state)
    Array.from(list.children).forEach(child => {
        if (child.id !== 'no-suggestions-text') {
            child.remove();
        }
    });

    if (items.length === 0) {
        noSuggestions.classList.remove('hidden');
        return;
    }

    noSuggestions.classList.add('hidden');

    items.forEach(item => {
        const listItem = document.createElement('div');
        listItem.className = 'list-item';

        let iconSvg = ICONS.login;
        let subtitle = "";

        if (item.type === 'card') {
            iconSvg = ICONS.card;
            const last4 = (item.number || "").slice(-4);
            subtitle = last4 ? `*${last4} ${item.brand || ""}` : item.brand;
        } else if (item.type === 'identity') {
            iconSvg = ICONS.identity;
            subtitle = `${item.firstName || ""} ${item.lastName || ""}`.trim();
        } else {
            subtitle = item.username || "No username";
        }

        listItem.innerHTML = `
            <div class="item-icon">${iconSvg}</div>
            <div class="item-details">
                <div class="item-name">${item.name}</div>
                <div class="item-subtitle">${subtitle}</div>
            </div>
            <div class="item-chevron">${ICONS.chevronRight}</div>
        `;

        listItem.addEventListener('click', () => {
            showDetails(item);
        });

        list.appendChild(listItem);
    });
}

// --- Details View Logic ---
const btnBack = document.getElementById('btn-back');
btnBack.addEventListener('click', () => {
    showView('unlocked');
});

function showDetails(item) {
    showView('details');

    document.getElementById('details-title').innerText = item.name;
    const iconContainer = document.getElementById('details-icon');

    const fieldsList = document.getElementById('details-fields-list');
    fieldsList.innerHTML = ''; // Clear fields

    let fields = [];

    if (item.type === 'login') {
        iconContainer.innerHTML = ICONS.login;
        fields.push({ label: 'Username', value: item.username });
        fields.push({ label: 'Password', value: item.password, isPassword: true });
    } else if (item.type === 'card') {
        iconContainer.innerHTML = ICONS.card;
        fields.push({ label: 'Cardholder Name', value: item.cardholderName });
        fields.push({ label: 'Number', value: item.number });
        fields.push({ label: 'Expiration', value: `${item.expMonth}/${item.expYear}` });
        fields.push({ label: 'Security Code', value: item.code });
    } else if (item.type === 'identity') {
        iconContainer.innerHTML = ICONS.identity;
        fields.push({ label: 'Name', value: `${item.firstName || ""} ${item.lastName || ""}`.trim() });
        fields.push({ label: 'Email', value: item.email });
        fields.push({ label: 'Phone', value: item.phone });
    }

    fields.forEach(field => {
        if (!field.value) return; // Skip empty fields

        const fieldItem = document.createElement('div');
        fieldItem.className = 'field-item';

        const displayValue = field.isPassword ? '••••••••' : field.value;

        fieldItem.innerHTML = `
            <div class="field-label">${field.label}</div>
            <div class="field-value-container">
                <div class="field-value">${displayValue}</div>
                <button class="btn-action-icon" aria-label="Copy ${field.label}" title="Copy">
                    ${ICONS.copy}
                </button>
            </div>
        `;

        const copyBtn = fieldItem.querySelector('.btn-action-icon');
        copyBtn.addEventListener('click', () => {
            navigator.clipboard.writeText(field.value).then(() => {
                // Visual feedback
                copyBtn.innerHTML = ICONS.check;
                setTimeout(() => {
                    copyBtn.innerHTML = ICONS.copy;
                }, 1500);
            });
        });

        fieldsList.appendChild(fieldItem);
    });
}
