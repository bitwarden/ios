import SwiftUI

/// A custom slider view that allows for a custom thumb view.
///
struct BitwardenSlider<ThumbView: View>: View {
    // MARK: Private Properties

    /// The size of the thumb view.
    @SwiftUI.State private var thumbSize: CGSize = .zero

    // MARK: Properties

    /// A closure containing the action to take when the slider begins or ends editing.
    let onEditingChanged: (Bool) -> Void

    /// The range of allowable values for the slider.
    let range: ClosedRange<Double>

    /// The distance between each valid value.
    let step: Double

    /// The custom thumb view to display on the slider.
    let thumbView: () -> ThumbView

    /// The current value of the slider.
    @Binding var value: Double

    // MARK: Default Colors

    /// The color of the slider track.
    var trackColor: Color = Asset.Colors.sliderTrack.swiftUIColor

    /// The color of the filled portion of the slider track.
    var filledTrackColor: Color = Asset.Colors.sliderFilled.swiftUIColor

    var body: some View {
        GeometryReader { geometry in
            let thumbPosition = thumbPosition(in: geometry.size)
            ZStack {
                Rectangle()
                    .fill(trackColor)
                    .frame(height: 4)
                    .cornerRadius(2)
                    .overlay(
                        Rectangle()
                            .fill(filledTrackColor)
                            .frame(width: thumbPosition, height: 4)
                            .cornerRadius(2),
                        alignment: .leading
                    )

                thumbView()
                    .onSizeChanged { size in
                        thumbSize = size
                    }
                    .position(x: max(0, thumbPosition), y: geometry.size.height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                self.value = valueFrom(position: value.location.x, in: geometry.size)
                                onEditingChanged(true)
                            }
                            .onEnded { _ in
                                onEditingChanged(false)
                            }
                    )
            }
        }
        .frame(height: 44)
        .accessibilityElement()
        .accessibilityValue(Text("\(Int(value))"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                let newValue = min(value + step, range.upperBound)
                value = newValue
                onEditingChanged(true)
                onEditingChanged(false)
            case .decrement:
                let newValue = max(value - step, range.lowerBound)
                value = newValue
                onEditingChanged(true)
                onEditingChanged(false)
            default:
                break
            }
        }
    }

    // MARK: Initialization

    /// Initialize a `BitwardenSlider`.
    ///
    /// - Parameters:
    ///   - value: The current value of the slider.
    ///   - range: The range of allowable values for the slider.
    ///   - step: The distance between each valid value.
    ///   - onEditingChanged: A closure containing the action to take when the slider begins or ends editing.
    ///   - thumbView: The custom thumb view to display on the slider.
    ///   - trackColor: The color of the slider track.
    ///   - filledTrackColor: The color of the filled portion of the slider track.
    ///
    init(
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double,
        onEditingChanged: @escaping (Bool) -> Void,
        @ViewBuilder thumbView: @escaping () -> ThumbView,
        trackColor: Color = Asset.Colors.sliderTrack.swiftUIColor,
        filledTrackColor: Color = Asset.Colors.sliderFilled.swiftUIColor
    ) {
        _value = value
        self.range = range
        self.step = step
        self.onEditingChanged = onEditingChanged
        self.thumbView = thumbView
        self.trackColor = trackColor
        self.filledTrackColor = filledTrackColor
    }

    // MARK: private methods

    /// Calculate the position of the thumb view based on the current `value`.
    private func thumbPosition(in size: CGSize) -> CGFloat {
        let availableWidth = size.width - thumbSize.width // Adjust for thumb size
        let relativeValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return availableWidth * CGFloat(relativeValue) + thumbSize.width / 2 // Adjust for thumb size
    }

    /// Calculate the `value` based on the position of the thumb view.
    private func valueFrom(position: CGFloat, in size: CGSize) -> Double {
        let availableWidth = size.width - thumbSize.width // Adjust for thumb size
        let relativePosition = (position - thumbSize.width / 2) / availableWidth // Adjust for thumb size
        let newValue = Double(relativePosition) * (range.upperBound - range.lowerBound) + range.lowerBound
        return min(max(newValue, range.lowerBound), range.upperBound)
    }
}
