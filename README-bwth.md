# Test Harness

A playground application for testing and demonstrating various Bitwarden iOS features and flows.

## Overview

The Test Harness app provides a simple interface to trigger and test different scenarios within the Bitwarden iOS ecosystem, including:

- Password Autofill flows
- Passkey Autofill flows (coming soon)
- Passkey Creation flows (coming soon)

## Purpose

This app is designed for:
- Manual testing of specific flows
- Demonstrating feature functionality
- Debugging and development
- Integration testing scenarios

## Structure

The app follows the same architectural patterns as the main Bitwarden apps:
- Coordinator-based navigation
- Processor/State/Action/Effect pattern for views
- Service container for dependency injection
- Sourcery for mock generation

## Building

The Test Harness is part of the main iOS workspace. To build:

1. Run `./Scripts/bootstrap.sh` to generate the Xcode project
2. Open `Bitwarden.xcworkspace`
3. Select the `TestHarness` scheme
4. Build and run

## Note

This is a development/testing tool and is not intended for production use or App Store distribution.
