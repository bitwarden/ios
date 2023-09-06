# Bitwarden iOS

## Contents

- [Compatibility](#compatibility)
- [Setup](#setup)
- [Dependencies](#dependencies)
- [Project Structure](#project-structure)

## Compatibility

- **Minimum iOS**: 15.0
- **Target SDK**: 15.0
- **Device Types Supported**: iPhone
- **Screen Sizes Supported**: iPhone SE to iPhone 14 Pro Max
- **Orientations Supported**: Portrait, Landscape

## Setup

1. Clone the repository:

    ```sh
    $ git clone https://github.com/bitwarden/ios
    ```

2. Install [Mint](https://github.com/yonaskolb/mint):

    ```sh
    $ brew install mint
    ```

    If you're using a Mac with Apple Silicon with Mint installed via Homebrew, you may see the SwiftGen build phase fail with the following error:

    `line 2: mint: command not found`

    If so, or if you just prefer to install Mint without `brew`, clone the Mint repo into a temporary directory and run `make`.

    ```sh
    $ git clone https://github.com/yonaskolb/Mint.git
    $ cd Mint
    $ make
    ```

3. Bootstrap the project:

    ```sh
    $ Scripts/bootstrap.sh
    ```

    > **Note**
    > Because `Scripts/bootstrap.sh` is how the project is generated, `bootstrap.sh` will need to be run every time the project configuration or file structure has changed (for example, when files have been added, removed or moved). It is typically best practice to run `bootstrap.sh` any time you switch branches or pull down changes.

    Alternatively, you can create git hooks to automatically execute the `bootstrap.sh` script every time a git hook occurs. To use the git hook scripts already defined in the `Scripts` directory, copy the scripts to the `.git/hooks` directory.

    ```sh
    $ cp Scripts/post-merge .git/hooks/
    $ cp Scripts/post-checkout .git/hooks/
    ```

### Run the App

1. Open the project in Xcode 14.3+.
2. Run the app in the Simulator with the `Bitwarden` target.

### Running Tests

1. In Xcode's toolbar, select the project and a connected device or simulator.
   - The `Generic iOS Device` used for builds will not work for testing.

2. In Xcode's menu bar, select `Product > Test`.
   - Test results appear in the Debug Area, which can be accessed from `View > Debug Area > Show Debug Area` if not already visible.

### Linting

This project is linted using both SwiftLint and SwiftFormat. Both tools run in linting mode with every build of the `Bitwarden` target. However, if you would like to have SwiftFormat autocorrect any issues that are discovered while linting, you can manually run the fix command `mint run swiftformat .`.

Additionally, if you would like SwiftFormat to autocorrect any issues before every commit, you can use a git hook script. To use the git hook script already defined in the `Scripts` directory, copy the script to the `.git/hooks` directory.

```sh
$ cp Scripts/pre-commit .git/hooks/
```

## Dependencies

### Icons
- The icons used in the app are all custom. No additional licensing is required.

### App Dependencies

- **Firebase Crashlytics**
    - https://github.com/firebase/firebase-ios-sdk
    - Purpose: SDK for crash and non-fatal error reporting.
    - License: Apache 2.0

### Development Dependencies

The following dependencies are used in the development environment only. They are not present in deployed code.

- **LicensePlist**
    - https://github.com/mono0926/LicensePlist
    - Purpose: A tool to generate a list of third-party software licenses displayed in app settings.
    - License: MIT
- **Mint**
    - https://github.com/yonaskolb/mint
    - Purpose: A package manager that installs and runs Swift command line tool packages.
    - License: MIT
- **SnapshotTesting**
    - https://github.com/pointfreeco/swift-snapshot-testing
    - Purpose: Allow a snapshot test case which renders a UI component, takes a snapshot, then compares it to a reference snapshot file stored alongside the test.
    - License: MIT
- **SwiftGen**
    - https://github.com/SwiftGen/SwiftGen
    - Purpose: A tool to automatically generate Swift code for project resources (like images, localized strings, etc), to make them type-safe to use.
    - License: MIT
- **SwiftFormat**
    - https://github.com/nicklockwood/SwiftFormat
    - Purpose: A tool used to reformat Swift code to automatically adjust for some style conventions.
    - License: MIT
- **SwiftLint**
    - https://github.com/realm/SwiftLint
    - Purpose: A tool to enforce Swift style and conventions.
    - License: MIT
- **ViewInspector**
    - https://github.com/nalexn/ViewInspector
    - Purpose: A tool used to unit test SwiftUI views.
    - License: MIT
- **XcodeGen**
    - https://github.com/yonaskolb/XcodeGen
    - Purpose: Generates the Xcode project using the folder structure and a project spec.
    - License: MIT

## Project Structure

### BitwardenShared

This project's structure is split into separate sections to support sharing as much code between all of the targets as possible. All core functionality and the majority of UI elements can be found in the `BitwardenShared` framework.

### GlobalTestHelpers

`GlobalTestHelpers` is a directory that contains helper files used in all test targets. This directory is included in each target that is defined in the `project.yml` file.
