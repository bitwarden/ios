[![Github Workflow build on main](https://github.com/bitwarden/authenticator-ios/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/bitwarden/authenticator-ios/actions/workflows/build.yml?query=branch:main)
[![Join the chat at https://gitter.im/bitwarden/Lobby](https://badges.gitter.im/bitwarden/Lobby.svg)](https://gitter.im/bitwarden/Lobby)

# Bitwarden Authenticator iOS App

<a href="https://apps.apple.com/app/bitwarden-authenticator/id6497335175" target="_blank"><img src="https://imgur.com/GdGqPMY.png" width="135" height="40"></a>

Bitwarden Authenticator allows you easily store and generate two-factor authentication codes on your device. The Bitwarden Authenticator iOS application is written in Swift.

<img src="https://raw.githubusercontent.com/bitwarden/brand/master/screenshots/authenticator-ios-codes.png" alt="" width="300" height="650" />

## Compatibility

- **Minimum iOS**: 15.0
- **Target SDK**: 15.0
- **Device Types Supported**: iPhone
- **Screen Sizes Supported**: iPhone SE to iPhone 14 Pro Max
- **Orientations Supported**: Portrait, Landscape

## Setup

1. Clone the repository:

    ```sh
    $ git clone https://github.com/bitwarden/authenticator-ios
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

1. Open the project in Xcode 15.2+.
2. Run the app in the Simulator with the `Authenticator` target.

### Running Tests

1. In Xcode's toolbar, select the project and a connected device or simulator.
   - The `Generic iOS Device` used for builds will not work for testing.

2. In Xcode's menu bar, select `Product > Test`.
   - Test results appear in the Debug Area, which can be accessed from `View > Debug Area > Show Debug Area` if not already visible.

### Linting

This project is linted using both SwiftLint and SwiftFormat. Both tools run in linting mode with every build of the `Authenticator` target. However, if you would like to have SwiftFormat autocorrect any issues that are discovered while linting, you can manually run the fix command `mint run swiftformat .`.

Additionally, if you would like SwiftFormat to autocorrect any issues before every commit, you can use a git hook script. To use the git hook script already defined in the `Scripts` directory, copy the script to the `.git/hooks` directory.

```sh
$ cp Scripts/pre-commit .git/hooks/
```

## Project Structure

### AuthenticatorShared

This project's structure is split into separate sections to support sharing as much code between all of the targets as possible. All core functionality and the majority of UI elements can be found in the `AuthenticatorShared` framework.

### GlobalTestHelpers

`GlobalTestHelpers` is a directory that contains helper files used in all test targets. This directory is included in each target that is defined in the `project.yml` file.

## Contribute

Code contributions are welcome! Please commit any pull requests against the `main` branch. Learn more about how to contribute by reading the [Contributing Guidelines](https://contributing.bitwarden.com/contributing/). Check out the [Contributing Documentation](https://contributing.bitwarden.com/) for how to get started with your first contribution.

Security audits and feedback are welcome. Please open an issue or email us privately if the report is sensitive in nature. You can read our security policy in the [`SECURITY.md`](SECURITY.md) file.
