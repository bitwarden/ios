import SwiftUI

/// A spinning circular activity indicator.
///
struct CircularActivityIndicator: View {
    // MARK: Properties

    /// Whether the activity indicator is spinning.
    @SwiftUI.State private var isSpinning = false

    /// The style of the stroke used in the indicator.
    private let strokeStyle = StrokeStyle(lineWidth: 6, lineCap: .round)

    // MARK: View

    var body: some View {
        ZStack {
            Circle()
                .stroke(Asset.Colors.backgroundTertiary.swiftUIColor, style: strokeStyle)

            Circle()
                .trim(from: 0, to: 0.65)
                .stroke(Asset.Colors.strokeBorder.swiftUIColor, style: strokeStyle)
                .rotationEffect(Angle(degrees: isSpinning ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isSpinning)
                .onAppear {
                    isSpinning = true
                }
        }
        .frame(width: 56, height: 56)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    CircularActivityIndicator()
}
#endif
