#if canImport(AVFAudio)

@preconcurrency import AVFAudio
import RealtimeSanitizer

// This example demonstrates how easily you can hook
// `RealtimeSanitizer` on the `AVAudioEngine`'s output node
// and sanitize all upstream nodes
// It also shows that Apple is using `pthread_mutex_lock` on the IOThread.
@available(macOS 13.0, iOS 16, *)
@main
struct Main {
    static let engine = AVAudioEngine()
    static let sampler = AVAudioUnitSampler()

    static func main() async throws {
        let token = engine.outputNode.auAudioUnit.token { @Sendable flags, _, _, _ in
            if flags.contains(.unitRenderAction_PreRender) {
                RealtimeSanitizer.realtimeEnter()
            }
            if flags.contains(.unitRenderAction_PostRender) {
                RealtimeSanitizer.realtimeExit()
            }
        }
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        try engine.start()

        sampler.overallGain = 0.5
        sampler.startNote(120, withVelocity: 127, onChannel: 0)

        try await Task.sleep(for: .seconds(10))

        engine.mainMixerNode.auAudioUnit.removeRenderObserver(token)
    }
}
#else
@main
struct Main {
    static func main() async throws {
        print("AVAudioEngine example is only available on Apple platforms")
    }
}
#endif // canImport(AVFAudio)
