import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared

// MARK: - AnimatedImagePlayerTests

@MainActor
struct AnimatedImagePlayerTests {
    // MARK: Tests

    /// `init(data:)` decodes the first frame of valid animated image data and starts paused.
    @Test
    func init_validData() throws {
        let subject = try AnimatedImagePlayer(data: #require(Data.testGif(frameCount: 3)))

        #expect(subject.currentFrame != nil)
        #expect(subject.frameIndex == 0)
        #expect(!subject.isPlaying)
    }

    /// `init(data:)` leaves `currentFrame` `nil` when the data can't be decoded.
    @Test
    func init_invalidData() {
        let subject = AnimatedImagePlayer(data: Data("not an image".utf8))

        #expect(subject.currentFrame == nil)
        #expect(!subject.isPlaying)
    }

    /// `pause()` stops the animation from advancing past the current frame.
    @Test
    func pause_stopsAdvancingFrames() async throws {
        let subject = try AnimatedImagePlayer(data: #require(Data.testGif(frameCount: 3)))
        subject.play()
        try await waitForAsync { subject.frameIndex > 0 }

        subject.pause()
        let pausedFrameIndex = subject.frameIndex
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!subject.isPlaying)
        #expect(subject.frameIndex == pausedFrameIndex)
    }

    /// `play()` advances through the animation's frames.
    @Test
    func play_advancesFrames() async throws {
        let subject = try AnimatedImagePlayer(data: #require(Data.testGif(frameCount: 3)))

        subject.play()

        #expect(subject.isPlaying)
        try await waitForAsync { subject.frameIndex > 0 }
    }

    /// `play()` doesn't start playing when the data can't be animated.
    @Test
    func play_invalidData() {
        let subject = AnimatedImagePlayer(data: Data("not an image".utf8))

        subject.play()

        #expect(!subject.isPlaying)
    }

    /// `togglePlayback()` alternates between playing and paused.
    @Test
    func togglePlayback() throws {
        let subject = try AnimatedImagePlayer(data: #require(Data.testGif(frameCount: 3)))

        subject.togglePlayback()
        #expect(subject.isPlaying)

        subject.togglePlayback()
        #expect(!subject.isPlaying)
    }
}
