// content.js
// Observes the DOM and injects the Bitwarden inline autofill icon

console.log("Bitwarden Safari Web Extension: Content script loaded.");

const BITWARDEN_ICON_CLASS = "bitwarden-inline-icon";
const INLINE_POPUP_ID = "bitwarden-inline-popup";

// SVG Icons
const ICON_DATA_URI = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1MTIgNTEyIj48cGF0aCBmaWxsPSIjMTc1REUwIiBkPSJNMjU2IDBMMjQgNjUuNXYyODFsMjMyIDE2NS41IDIzMi0xNjUuNVY2NS41THoyIi8+PC9zdmc+";
const ICONS = {
    login: '<svg viewBox="0 0 512 512"><path fill="currentColor" d="M256 0L24 65.5v281l232 165.5 232-165.5V65.5L256 0z"/></svg>',
    card: '<svg viewBox="0 0 512 512"><path fill="currentColor" d="M480 80H32C14.33 80 0 94.33 0 112v288c0 17.67 14.33 32 32 32h448c17.67 0 32-14.33 32-32V112c0-17.67-14.33-32-32-32zM96 352H64v-32h32v32zm0-64H64v-32h32v32zm0-64H64v-32h32v32zm384 128H160v-32h320v32zm0-64H160v-32h320v32zm0-64H160v-32h320v32z"/></svg>',
    identity: '<svg viewBox="0 0 512 512"><path fill="currentColor" d="M384 128h-32V96c0-17.67-14.33-32-32-32H96C78.33 64 64 78.33 64 96v256c0 17.67 14.33 32 32 32h32v32c0 17.67 14.33 32 32 32h224c17.67 0 32-14.33 32-32V160c0-17.67-14.33-32-32-32zm-64 224H160v-64h160v64zm0-96H160v-64h160v64z"/></svg>',
    unlock: '<svg viewBox="0 0 448 512"><path fill="currentColor" d="M144 192H384C419.3 192 448 220.7 448 256V448C448 483.3 419.3 512 384 512H64C28.65 512 0 483.3 0 448V256C0 220.7 28.65 192 64 192H80V144C80 64.47 144.5 0 224 0C281.5 0 331 33.69 354.1 82.27C361.7 98.23 354.9 117.3 338.1 124.9C322.9 132.5 303.9 125.7 296.3 109.8C283.4 82.63 255.9 64 224 64C179.8 64 144 99.82 144 144V192H144zM224 288C197.5 288 176 309.5 176 336C176 362.5 197.5 384 224 384C250.5 384 272 362.5 272 336C272 309.5 250.5 288 224 288z"/></svg>',
    external: '<svg viewBox="0 0 448 512"><path fill="currentColor" d="M432 320H400c-8.8 0-16 7.2-16 16V448H64V128H208c8.8 0 16-7.2 16-16V80c0-8.8-7.2-16-16-16H48c-26.5 0-48 21.5-48 48V464c0 26.5 21.5 48 48 48H400c26.5 0 48-21.5 48-48V336c0-8.8-7.2-16-16-16zM488 0H336c-13.3 0-24 10.7-24 24s10.7 24 24 24h66.7L215.1 235.6c-9.4 9.4-9.4 24.6 0 33.9s24.6 9.4 33.9 0L440 78.6l10.7 10.7V24c0-13.3-10.7-24-24-24z"/></svg>'
};

// Heuristics
const Heuristics = {
    username: [/username/i, /user/i, /login/i, /email/i, /e-mail/i],
    password: [/password/i, /pass/i, /pwd/i],
    cardName: [/ccname/i, /cardname/i, /cardholder/i],
    cardNumber: [/ccnumber/i, /cardnumber/i, /card-number/i, /creditcard/i],
    cardExp: [/exp/i, /expiration/i],
    cardCvv: [/cvc/i, /cvv/i, /csc/i, /securitycode/i, /cvn/i],
    address: [/address/i, /street/i, /city/i, /state/i, /zip/i, /postal/i, /country/i, /province/i],
    identityName: [/firstname/i, /lastname/i, /fullname/i, /name/i],
    phone: [/phone/i, /tel/i, /mobile/i]
};

function determineFieldType(input) {
    if (input.type === 'password') return 'password';

    // Combine attributes to check against patterns
    const attrs = [
        input.id,
        input.name,
        input.placeholder,
        input.getAttribute('autocomplete'),
        input.getAttribute('aria-label')
    ].filter(Boolean).join(' ');

    // Check CC
    if (Heuristics.cardNumber.some(r => r.test(attrs))) return 'cardNumber';
    if (Heuristics.cardName.some(r => r.test(attrs))) return 'cardName';
    if (Heuristics.cardExp.some(r => r.test(attrs))) return 'cardExp';
    if (Heuristics.cardCvv.some(r => r.test(attrs))) return 'cardCvv';

    // Check Identity
    if (Heuristics.address.some(r => r.test(attrs))) return 'address';
    if (Heuristics.identityName.some(r => r.test(attrs))) return 'identityName';
    if (Heuristics.phone.some(r => r.test(attrs))) return 'phone';

    // Check Login
    if (input.type === 'email' || Heuristics.username.some(r => r.test(attrs))) return 'username';

    return 'unknown';
}

function injectIcon(inputField) {
    if (inputField.parentElement.querySelector(`.${BITWARDEN_ICON_CLASS}`)) {
        return; // Already injected
    }

    const wrapper = document.createElement('div');
    wrapper.style.position = 'relative';
    wrapper.style.display = 'inline-block';

    // Try to match width but keep it unobtrusive
    const width = window.getComputedStyle(inputField).width;
    wrapper.style.width = width !== 'auto' ? width : '100%';

    inputField.parentNode.insertBefore(wrapper, inputField);
    wrapper.appendChild(inputField);

    const icon = document.createElement('img');
    icon.src = ICON_DATA_URI;
    icon.className = BITWARDEN_ICON_CLASS;
    icon.style.position = 'absolute';
    icon.style.right = '8px';
    icon.style.top = '50%';
    icon.style.transform = 'translateY(-50%)';
    icon.style.width = '20px';
    icon.style.height = '20px';
    icon.style.cursor = 'pointer';
    icon.style.zIndex = '10000';

    icon.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        showPopup(inputField, icon);
    });

    wrapper.appendChild(icon);
}

function showPopup(inputField, icon) {
    // Remove existing popup if any
    const existing = document.getElementById(INLINE_POPUP_ID);
    if (existing) {
        existing.remove();
    }

    // Ask background to fetch items from native vault
    browser.runtime.sendMessage({
        type: "getItems",
        url: window.location.href
    }).then(response => {
        if (response.error) {
            console.error(response.error);
            renderPopup(inputField, icon, [], response.error);
        } else {
            renderPopup(inputField, icon, response.items || []);
        }
    }).catch(err => {
        console.error("Error fetching items:", err);
        renderPopup(inputField, icon, [], "Communication error");
    });
}

function renderPopup(inputField, icon, items, errorMsg = null) {
    const popup = document.createElement('div');
    popup.id = INLINE_POPUP_ID;

    // Position the popup below the input field
    const rect = inputField.getBoundingClientRect();
    popup.style.top = (window.scrollY + rect.bottom + 8) + 'px';
    popup.style.left = (window.scrollX + rect.left) + 'px';

    if (errorMsg) {
        if (errorMsg === "Vault is locked") {
            popup.innerHTML = `
                <div class="bw-popup-padded-container">
                    <div class="locked-header">Unlock your account to view autofill suggestions</div>
                    <div class="inline-menu-list-actions-item unlock-button" id="unlock-vault-btn">
                        <div class="cipher-container">
                            <div class="cipher-icon">${ICONS.unlock}</div>
                            <div class="cipher-details">
                                <span class="cipher-name">Unlock account</span>
                            </div>
                        </div>
                    </div>
                </div>
            `;
            setTimeout(() => {
                const btn = popup.querySelector("#unlock-vault-btn");
                btn.addEventListener('click', () => {
                    browser.runtime.sendMessage({ type: "openPopup" });
                    popup.remove();
                });
            }, 0);
        } else {
            popup.innerHTML = `
                <div class="bw-popup-error-container">
                    <svg class="bw-popup-error-icon" viewBox="0 0 512 512"><path fill="currentColor" d="M256 32c14.2 0 27.3 7.5 34.5 19.8l216 368c7.3 12.4 7.3 27.7 .2 40.1S486.3 480 472 480H40c-14.3 0-27.6-7.7-34.7-20.1s-7-27.8 .2-40.1l216-368C228.7 39.5 241.8 32 256 32zm0 128c-13.3 0-24 10.7-24 24V296c0 13.3 10.7 24 24 24s24-10.7 24-24V184c0-13.3-10.7-24-24-24zm32 224a32 32 0 1 0 -64 0 32 32 0 1 0 64 0z"/></svg>
                    <div class="bw-popup-error-text">${errorMsg}</div>
                </div>
            `;
        }
    } else if (items.length === 0) {
        popup.innerHTML = `<div class="bw-popup-empty">No matching items found</div>`;
    } else {
        const container = document.createElement('div');
        container.className = 'bw-popup-padded-container';

        const header = document.createElement('div');
        header.className = 'autofill-header';
        header.innerText = 'Select a login to autofill';
        container.appendChild(header);

        const list = document.createElement('div');
        list.className = 'inline-menu-list-actions';

        items.forEach(item => {
            const row = document.createElement('div');
            row.className = 'inline-menu-list-actions-item';

            let iconSvg = ICONS.login;
            let subtitle = "";

            if (item.type === 'card') {
                iconSvg = ICONS.card;
                const last4 = (item.number || "").slice(-4);
                subtitle = last4 ? `*${last4} ${item.brand || ""}` : item.brand;
            } else if (item.type === 'identity') {
                iconSvg = ICONS.identity;
                subtitle = `${item.firstName || ""} ${item.lastName || ""}`.trim();
                if (!subtitle && item.email) subtitle = item.email;
            } else {
                subtitle = item.username || "No username";
            }

            row.innerHTML = `
                <div class="cipher-container">
                    <div class="cipher-icon">${iconSvg}</div>
                    <div class="cipher-details">
                        <span class="cipher-name">${item.name}</span>
                        <span class="cipher-subtitle">${subtitle}</span>
                    </div>
                    <div class="cipher-external-icon">${ICONS.external}</div>
                </div>
            `;

            row.addEventListener('click', () => {
                fillForm(inputField.form, item);
                popup.remove();
            });
            list.appendChild(row);
        });

        container.appendChild(list);
        popup.appendChild(container);
    }

    document.body.appendChild(popup);

    // Close when clicking outside
    const closePopup = (e) => {
        if (!popup.contains(e.target) && e.target !== icon) {
            popup.remove();
            document.removeEventListener('click', closePopup);
        }
    };

    setTimeout(() => {
        document.addEventListener('click', closePopup);
    }, 10);
}

function fillForm(form, item) {
    if (!form) return;

    const inputs = form.querySelectorAll('input, select');
    inputs.forEach(input => {
        const fieldType = determineFieldType(input);

        if (item.type === 'login') {
            if (fieldType === 'username' && item.username) input.value = item.username;
            else if (fieldType === 'password' && item.password) input.value = item.password;
        } else if (item.type === 'card') {
            if (fieldType === 'cardName' && item.cardholderName) input.value = item.cardholderName;
            else if (fieldType === 'cardNumber' && item.number) input.value = item.number;
            else if (fieldType === 'cardExp' && item.expMonth && item.expYear) input.value = `${item.expMonth}/${item.expYear}`;
            else if (fieldType === 'cardCvv' && item.code) input.value = item.code;
        } else if (item.type === 'identity') {
            if (fieldType === 'identityName') {
                // simple fallback if "first name" specifically isn't distinguished
                const attrs = (input.name + input.id).toLowerCase();
                if (attrs.includes('first')) input.value = item.firstName || "";
                else if (attrs.includes('last')) input.value = item.lastName || "";
                else input.value = `${item.firstName || ""} ${item.lastName || ""}`.trim();
            }
            else if (fieldType === 'address') {
                const attrs = (input.name + input.id).toLowerCase();
                if (attrs.includes('city')) input.value = item.city || "";
                else if (attrs.includes('state') || attrs.includes('province')) input.value = item.state || "";
                else if (attrs.includes('postal') || attrs.includes('zip')) input.value = item.postalCode || "";
                else if (attrs.includes('country')) input.value = item.country || "";
                else if (attrs.includes('2')) input.value = item.address2 || "";
                else input.value = item.address1 || "";
            }
            else if (fieldType === 'phone' && item.phone) input.value = item.phone;
            else if (fieldType === 'username' && item.email) input.value = item.email; // use email for generic user fields in identity context
        }

        // Dispatch events so React/Vue/Angular notice the change
        if (input.value) {
            input.dispatchEvent(new Event('input', { bubbles: true }));
            input.dispatchEvent(new Event('change', { bubbles: true }));
        }
    });
}

function scanDOM() {
    const inputs = document.querySelectorAll('input:not([type="hidden"]):not([type="submit"]):not([type="button"])');
    let injectedCount = 0;

    inputs.forEach(input => {
        const type = determineFieldType(input);
        if (type !== 'unknown') {
            injectIcon(input);
            injectedCount++;
        }
    });

    if (injectedCount > 0) {
        console.log(`Bitwarden Safari Web Extension: Injected ${injectedCount} icons.`);
    }
}

// Initial scan
scanDOM();

// Re-scan on DOM mutations
const observer = new MutationObserver((mutations) => {
    let shouldScan = false;
    for (const mutation of mutations) {
        if (mutation.addedNodes.length > 0) {
            shouldScan = true;
            break;
        }
    }
    if (shouldScan) {
        scanDOM();
    }
});

observer.observe(document.body, { childList: true, subtree: true });
