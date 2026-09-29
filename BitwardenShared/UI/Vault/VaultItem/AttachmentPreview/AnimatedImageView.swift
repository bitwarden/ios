import BitwardenResources
import Foundation
import ImageIO
import SwiftUI

// MARK: - AnimatedImageView

/// A view that plays animated image data (e.g. a GIF) with pinch-to-zoom and drag-to-pan gestures.
/// Tapping the image toggles playback. The animation plays automatically unless Reduce Motion is
/// enabled, in which case it starts paused on the first frame. Enabling Reduce Motion while the
/// animation is playing pauses it.
///
struct AnimatedImageView: View {
    // MARK: Private Properties

    /// The player that decodes and advances the animation's frames.
    @StateObject private var player: AnimatedImagePlayer

    /// Whether the user has enabled the Reduce Motion accessibility setting.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: View

    var body: some View {
        if let frame = player.currentFrame {
            ZoomableView {
                Image(decorative: frame, scale: 1)
                    .resizable()
                    .scaledToFit()
            }
            .overlay {
                if !player.isPlaying {
                    playIndicator
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { player.togglePlayback() })
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(player.isPlaying ? Localizations.pauseAnimation : Localizations.playAnimation)
            .accessibilityAddTraits([.isButton, .startsMediaSession])
            .accessibilityAction { player.togglePlayback() }
            .accessibilityIdentifier("AttachmentPreviewAnimatedImage")
            .onAppear {
                guard !reduceMotion else { return }
                player.play()
            }
            .onDisappear {
                player.pause()
            }
            .onChange(of: reduceMotion) { isReduceMotionEnabled in
                // Pause if Reduce Motion is turned on mid-view. The user can still tap to play.
                guard isReduceMotionEnabled else { return }
                player.pause()
            }
        }
    }

    /// The play indicator shown over the image while the animation is paused.
    private var playIndicator: some View {
        // TODO: PM-33413 swap in the final play icon once design provides it.
        Image(systemName: "play.circle.fill")
            .resizable()
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, .black.opacity(0.5))
            .frame(width: Self.playIndicatorSize, height: Self.playIndicatorSize)
            .allowsHitTesting(false)
    }

    // MARK: Initialization

    /// Creates a new `AnimatedImageView`.
    ///
    /// - Parameter data: The animated image data to display.
    ///
    init(data: Data) {
        _player = StateObject(wrappedValue: AnimatedImagePlayer(data: data))
    }
}

// MARK: - Constants

private extension AnimatedImageView {
    /// The width and height of the play indicator.
    static let playIndicatorSize: CGFloat = 64
}

// MARK: - AnimatedImagePlayer

/// An object that plays animated image data frame by frame using ImageIO, which decodes frames
/// on demand rather than holding every frame in memory.
///
@MainActor
final class AnimatedImagePlayer: ObservableObject {
    // MARK: Properties

    /// The frame currently being displayed.
    @Published private(set) var currentFrame: CGImage?

    /// The index of the frame currently being displayed, used to resume playback where it paused.
    private(set) var frameIndex = 0

    /// Whether the animation is currently playing.
    @Published private(set) var isPlaying = false

    // MARK: Private Properties

    /// The animated image data.
    private let data: Data

    /// Incremented each time playback starts, so an animation from a previous play/pause cycle
    /// that hasn't stopped yet can detect that it's been superseded.
    private var playbackGeneration = 0

    // MARK: Initialization

    /// Creates a new `AnimatedImagePlayer`, showing the first frame of the animation.
    ///
    /// - Parameter data: The animated image data to play.
    ///
    init(data: Data) {
        self.data = data
        if let source = CGImageSourceCreateWithData(data as CFData, nil) {
            currentFrame = CGImageSourceCreateImageAtIndex(source, 0, nil)
        }
    }

    // MARK: Methods

    /// Pauses the animation on the current frame.
    func pause() {
        isPlaying = false
    }

    /// Starts or resumes the animation from the current frame, looping indefinitely.
    func play() {
        guard !isPlaying else { return }
        isPlaying = true
        playbackGeneration += 1
        let generation = playbackGeneration

        let options: [CFString: Any] = [
            kCGImageAnimationStartIndex: frameIndex,
            kCGImageAnimationLoopCount: kCFNumberPositiveInfinity as Any,
        ]
        let status = CGAnimateImageDataWithBlock(
            data as CFData,
            options as CFDictionary,
        ) { [weak self] index, image, stop in
            // ImageIO invokes the animation block on the main queue.
            MainActor.assumeIsolated {
                guard let self, self.isPlaying, generation == self.playbackGeneration else {
                    stop.pointee = true
                    return
                }
                self.frameIndex = index
                self.currentFrame = image
            }
        }
        if status != noErr {
            isPlaying = false
        }
    }

    /// Toggles between playing and pausing the animation.
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
}
