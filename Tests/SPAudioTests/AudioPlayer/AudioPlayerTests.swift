import XCTest
@testable import SPAudio
import AVFoundation

final class AudioPlayerTests: XCTestCase {
    // MARK: DEFINE VARS
    let audioEngine = AudioEngine()
    static let testFileName = "test.aiff"
    static let temporaryDirectory = FileManager.default.temporaryDirectory
    var testFileURL: URL {
        return AudioPlayerTests.temporaryDirectory.appendingPathComponent(
            AudioPlayerTests.testFileName
        )
    }
    
    // MARK: SETUP
    override func setUpWithError() throws {
        try? FileManager.default.removeItem(at: self.testFileURL)
        _ = try AudioEngine.createAudioFileTestSignal(
            at: self.testFileURL,
            sampleRate: 16000,
            length: 16000
        )
    }
    
    // MARK: TEAR DOWN
    override func tearDown() {
        try? FileManager.default.removeItem(at: self.testFileURL)
    }
    
    
    func testLoadingAudio() {
        do {
            let mixer = AVAudioMixerNode()
            let connectionPoint = AVAudioConnectionPoint(node: mixer, bus: 0)
            let audioPlayer = AudioPlayer(
                audioEngine: self.audioEngine,
                outputConnectionPoints: [connectionPoint]
            )
            try audioPlayer.cue(self.testFileURL)
            switch audioPlayer.playerState {
            case .cued: XCTAssertTrue(true)
            case .standby: XCTFail("Incorrect state after loading.")
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    static var allTests = [
        ("testLoadingAudio", testLoadingAudio),
    ]
}

