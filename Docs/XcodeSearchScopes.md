# Xcode Search Custom Scopes

## What are Xcode Search Scopes?

Xcode's Find navigator supports custom search scopes that let you filter which files are searched. For example, you can limit a search to Swift source files only, or exclude test and localization files to focus on production code.

Custom scopes are stored in `xcuserdata/`, which is gitignored because it contains per-user Xcode state. This folder provides a shared template and a script to install the scopes into your local workspace without committing user-specific paths.

## Setup

Run the setup script from the repo root:

```bash
bash Scripts/setup-search-scopes.sh
```

The script installs the scopes into:
```
Bitwarden.xcworkspace/xcuserdata/<your-username>.xcuserdatad/IDEFindNavigatorScopes.plist
```

If a `IDEFindNavigatorScopes.plist` file already exists (e.g. you have your own custom scopes), the script will prompt you to:
- **Overwrite** — replace entirely with the shared template
- **Merge** — append only the template scopes not already present (matched by name)
- **Cancel** — make no changes

**Note:** This script is not run automatically by `bootstrap.sh`. Run it manually whenever the shared scopes are updated.

After running the script, **restart Xcode** for the new scopes to appear in the Find navigator.

## Available Scopes

| Name | Description |
|---|---|
| **Not Tests** | Excludes files whose names end in `Tests.swift`. Useful when searching for production code without noise from test files. |
| **Not in Localizations** | Excludes `Localizable.strings` and `Localizations.swift`. Useful when searching for code references without matching localization keys or generated string accessors. |

## Using a Scope

1. Open the Find navigator (⌘3) and switch to the **Find** tab.
2. Click the scope dropdown (defaults to "In Workspace") next to the search field.
3. Select a custom scope from the list.

## Adding a New Scope

1. In Xcode's Find navigator, click the scope dropdown and choose **New Scope…**
2. Configure the scope's name, predicates, and source in the editor.
3. Save the scope — Xcode writes it to your local `IDEFindNavigatorScopes.plist`.
4. Open `Bitwarden.xcworkspace/xcuserdata/<your-username>.xcuserdatad/IDEFindNavigatorScopes.plist` and copy the new `<dict>` entry for your scope.
5. Paste it into `Xcode/SearchScopes/IDEFindNavigatorScopes.plist` in the repo.
6. Open a PR with the change so teammates can merge it via the setup script.
