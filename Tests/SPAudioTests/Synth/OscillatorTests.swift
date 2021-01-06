import XCTest
@testable import SPAudio
import AVFoundation

final class OscillatorTests: XCTestCase {
    // MARK: DEFINE VARS
    private var audioEngine = AudioEngine()
//    static let testFileName = "test.aiff"
//    static let temporaryDirectory = FileManager.default.temporaryDirectory
//    var testFileURL: URL {
//        return AudioPlayerTests.temporaryDirectory.appendingPathComponent(
//            AudioPlayerTests.testFileName
//        )
//    }
    private var mixer = AVAudioMixerNode()
    var connectionPoint: AVAudioConnectionPoint {
        return AVAudioConnectionPoint(node: mixer, bus: 0)
    }
    
    // MARK: SETUP
    override func setUpWithError() throws {
        let audioEngine = AudioEngine()
        let mixer = AVAudioMixerNode()
        audioEngine.engine.attach(mixer)
        audioEngine.engine.connect(
            mixer,
            to: audioEngine.engine.outputNode,
            format: nil
        )
        // SILENCES TEST
        mixer.outputVolume = 0
        
        
        self.audioEngine = audioEngine
        self.mixer = mixer
        
//        try? FileManager.default.removeItem(at: self.testFileURL)
//        _ = try AudioEngine.createAudioFileTestSignal(
//            at: self.testFileURL,
//            sampleRate: 16000,
//            length: 16000
//        )
    }
    
    
    // MARK: TEST CONNECT
    func testConnect() throws {
        // ARRANGE
        let oscillator = OscillatorNode(
            wire: self.connectionPoint,
            engine: self.audioEngine
        )
        
        // ACT
        try oscillator.connect()
        try audioEngine.start()
        
        // ASSET
        XCTAssert(oscillator.isConnected)
    }
    
    // MARK: TEST DISCONNECT
    func testDisconnect() throws {
        // ARRANGE
        let oscillator = OscillatorNode(
            wire: self.connectionPoint,
            engine: self.audioEngine
        )
        try audioEngine.start()
        try oscillator.connect()
        
        // ACT
        oscillator.disconnect()
        
        // ASSET
        XCTAssert(!oscillator.isConnected)
    }
    
    
    
    static var allTests = [
        ("testConnect", testConnect),
        ("testDisconnect", testDisconnect),
    ]
}
