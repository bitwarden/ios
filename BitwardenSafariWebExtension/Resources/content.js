// content.js
// Observes the DOM and injects the Bitwarden inline autofill icon

console.log("Bitwarden Safari Web Extension: Content script loaded.");

const BITWARDEN_ICON_CLASS = "bitwarden-inline-icon";
const INLINE_POPUP_ID = "bitwarden-inline-popup";

// Simple image data URI for the icon
const ICON_DATA_URI = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1MTIgNTEyIj48cGF0aCBmaWxsPSIjMTc1REUwIiBkPSJNMjU2IDBMMjQgNjUuNXYyODFsMjMyIDE2NS41IDIzMi0xNjUuNVY2NS41THoyIi8+PC9zdmc+";

function injectIcon(inputField) {
    if (inputField.parentElement.querySelector(`.${BITWARDEN_ICON_CLASS}`)) {
        return; // Already injected
    }

    console.log("Bitwarden Safari Web Extension: Injecting icon into input", inputField);

    const wrapper = document.createElement('div');
    wrapper.style.position = 'relative';
    wrapper.style.display = 'inline-block';
    wrapper.style.width = inputField.offsetWidth + 'px';

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
    popup.style.top = (window.scrollY + rect.bottom + 5) + 'px';
    popup.style.left = (window.scrollX + rect.left) + 'px';
    popup.style.width = Math.max(rect.width, 250) + 'px';

    if (errorMsg) {
        popup.innerHTML = `<div class="bw-popup-error">${errorMsg}</div>`;
    } else if (items.length === 0) {
        popup.innerHTML = `<div class="bw-popup-empty">No matching logns found</div>`;
    } else {
        const list = document.createElement('ul');
        list.className = 'bw-popup-list';

        items.forEach(item => {
            const li = document.createElement('li');
            li.innerHTML = `<strong>${item.name}</strong><br><small>${item.username}</small>`;
            li.addEventListener('click', () => {
                fillForm(inputField.form, item);
                popup.remove();
            });
            list.appendChild(li);
        });
        popup.appendChild(list);
    }

    document.body.appendChild(popup);

    // Close when clicking outside
    const closePopup = (e) => {
        if (!popup.contains(e.target) && e.target !== icon) {
            popup.remove();
            document.removeEventListener('click', closePopup);
        }
    };

    // slight delay to prevent immediate trigger
    setTimeout(() => {
        document.addEventListener('click', closePopup);
    }, 10);
}

function fillForm(form, item) {
    if (!form) return;

    const inputs = form.querySelectorAll('input');
    inputs.forEach(input => {
        const type = input.type.toLowerCase();
        const name = (input.name || "").toLowerCase();

        if (type === 'text' || type === 'email' || name.includes('user') || name.includes('email')) {
            if (item.username) input.value = item.username;
        } else if (type === 'password' || name.includes('pass')) {
            if (item.password) input.value = item.password;
        }
    });
}

function scanDOM() {
    console.log("Bitwarden Safari Web Extension: Scanning DOM for input fields...");
    const inputs = document.querySelectorAll('input[type="text"], input[type="email"], input[type="password"]');
    let injectedCount = 0;

    inputs.forEach(input => {
        // Basic heuristic to only inject on likely login fields
        const name = (input.name || "").toLowerCase();
        if (input.type === 'password' || name.includes('user') || name.includes('email') || name.includes('login')) {
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
