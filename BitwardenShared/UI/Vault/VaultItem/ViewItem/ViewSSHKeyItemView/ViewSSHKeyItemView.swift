import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - ViewSSHKeyItemView

/// A view for displaying the contents of an SSH key item.
struct ViewSSHKeyItemView: View {
    // MARK: Properties

    /// Whether all copy buttons are shown.
    var showCopyButtons: Bool

    /// The `Store` for this view.
    @ObservedObject var store: Store<SSHKeyItemState, ViewSSHKeyItemAction, Void>

    var body: some View {
        ContentBlock {
            privateKeyField

            publicKeyField

            fingerprintField
        }
    }

    /// The private key field.
    @ViewBuilder private var privateKeyField: some View {
        let privateKey = store.state.privateKey
        BitwardenField(title: Localizations.privateKey) {
            PasswordText(password: privateKey, isPasswordVisible: store.state.isPrivateKeyVisible)
                .styleGuide(.body)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                .accessibilityIdentifier("PrivateKeyEntry")
        } accessoryContent: {
            if store.state.canViewPrivateKey {
                PasswordVisibilityButton(
                    accessibilityIdentifier: "PrivateKeyVisibilityToggle",
                    isPasswordVisible: store.state.isPrivateKeyVisible
                ) {
                    store.send(.privateKeyVisibilityPressed)
                }

                if showCopyButtons {
                    Button {
                        store.send(.copyPressed(value: privateKey, field: .sshPrivateKey))
                    } label: {
                        Asset.Images.copy24.swiftUIImage
                            .imageStyle(.accessoryIcon24)
                    }
                    .accessibilityLabel(Localizations.copy)
                    .accessibilityIdentifier("SSHKeyCopyPrivateKeyButton")
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// The public key field.
    ///
    @ViewBuilder private var publicKeyField: some View {
        let publicKey = store.state.publicKey
        BitwardenTextValueField(
            title: Localizations.publicKey,
            value: publicKey,
            valueAccessibilityIdentifier: "SSHKeyPublicKeyEntry"
        ) {
            if showCopyButtons {
                Button {
                    store.send(.copyPressed(value: publicKey, field: .sshPublicKey))
                } label: {
                    Asset.Images.copy24.swiftUIImage
                        .imageStyle(.accessoryIcon24)
                }
                .accessibilityLabel(Localizations.copy)
                .accessibilityIdentifier("SSHKeyCopyPublicKeyButton")
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// The username field.
    ///
    @ViewBuilder private var fingerprintField: some View {
        let keyFingerprint = store.state.keyFingerprint
        BitwardenTextValueField(
            title: Localizations.fingerprint,
            value: keyFingerprint,
            valueAccessibilityIdentifier: "FingerprintEntry"
        ) {
            if showCopyButtons {
                Button {
                    store.send(.copyPressed(value: keyFingerprint, field: .sshKeyFingerprint))
                } label: {
                    Asset.Images.copy24.swiftUIImage
                        .imageStyle(.accessoryIcon24)
                }
                .accessibilityLabel(Localizations.copy)
                .accessibilityIdentifier("SSHKeyCopyFingerprintButton")
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview("SSH Key item view") {
    NavigationView {
        ScrollView {
            LazyVStack(spacing: 20) {
                ViewSSHKeyItemView(
                    showCopyButtons: true,
                    store: Store(
                        processor: StateProcessor(
                            state: SSHKeyItemState(
                                isPrivateKeyVisible: false,
                                privateKey: "ajsdfopij1ZXCVZXC12312QW",
                                publicKey: "ssh-ed25519 AAAAA/asdjfoiwejrpo23323j23ASdfas",
                                keyFingerprint: "SHA-256:2qwer233ADJOIq1adfweqe21321qw"
                            )
                        )
                    )
                )
            }
            .padding(16)
        }
        .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
        .ignoresSafeArea()
    }
}
