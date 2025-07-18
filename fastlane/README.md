fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios upload_build

```sh
[bundle exec] fastlane ios upload_build
```

Push a new build to TestFlight

### ios release_beta

```sh
[bundle exec] fastlane ios release_beta
```

Push a new mobile build to bitwarden_beta

### ios release_to_production

```sh
[bundle exec] fastlane ios release_to_production
```

Push a new mobile build to Bitwarden Password Manager or Authenticator

This project uses Fastlane's Deliver tool to manage App Store metadata. Localized metadata is stored in subdirectories under:

fastlane/metadata_bwa_prod
fastlane/metadata_bwpm_prod

Inside each locale directory, you’ll find text files for default metadata like description.txt, keywords.txt, and release_notes.txt that are used during App Store submissions.

💡 These directories are read automatically by deliver during metadata upload and should be kept in sync when marketing content is updated.

----


## Mac

### mac release_beta

```sh
[bundle exec] fastlane mac release_beta
```

Push a new Mac desktop build to bitwarden_beta

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
