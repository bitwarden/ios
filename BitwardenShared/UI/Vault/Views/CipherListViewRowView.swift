import BitwardenSdk
import SwiftUI

// MARK: - CipherListViewRowView

/// A view for displaying a `CipherListView` item as a row in a list.
struct CipherListViewRowView: View {
    // MARK: Properties

    /// The item to display.
    var item: CipherListView

    var body: some View {
        HStack(spacing: 16) {
            Image(decorative: Asset.Images.globe)
                .resizable()
                .frame(width: 22, height: 22)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .font(.styleGuide(.body))
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                Text(item.subTitle)
                    .font(.styleGuide(.subheadline))
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
            }
            .padding(.vertical, 9)

            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.subTitle)")
    }
}

// MARK: Previews

#if DEBUG
struct CipherListViewRowView_Previews: PreviewProvider {
    static var previews: some View {
        CipherListViewRowView(
            item: CipherListView(
                id: UUID().uuidString,
                organizationId: nil,
                folderId: nil,
                collectionIds: [],
                name: "Example",
                subTitle: "email@example.com",
                type: .login,
                favorite: true,
                reprompt: .none,
                edit: false,
                viewPassword: true,
                attachments: 0,
                creationDate: Date(),
                deletedDate: nil,
                revisionDate: Date()
            )
        )
    }
}
#endif
