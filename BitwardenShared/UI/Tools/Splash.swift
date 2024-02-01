import SwiftUI

// MARK: - Splash

public struct Splash: View, Equatable {
    // MARK: Properties

    /// The background color
    ///
    let backgroundColor: Color

    /// Should the nav bar be hidden?
    ///
    let hidesNavBar: Bool

    /// Should the view display the logo?
    ///
    let showsLogo: Bool

    // MARK: View

    public var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            if showsLogo {
                Asset.Images.logo.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 238)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(hidesNavBar)
        .navigationBarBackButtonHidden(hidesNavBar)
    }

    // MARK: Initializers

    public init(
        backgroundColor: Color = Asset.Colors.backgroundPrimary.swiftUIColor,
        hidesNavBar: Bool = true,
        showsLogo: Bool = true
    ) {
        self.backgroundColor = backgroundColor
        self.hidesNavBar = hidesNavBar
        self.showsLogo = showsLogo
    }
}
