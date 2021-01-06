import XCTest
@testable import SPAudio
import AVFoundation

class AudioSetupXCTTestCase: XCTestCase {
    // MARK: DEFINE VARS
    var audioEngine = AudioEngine()
//    static let testFileName = "test.aiff"
//    static let temporaryDirectory = FileManager.default.temporaryDirectory
//    var testFileURL: URL {
//        return AudioPlayerTests.temporaryDirectory.appendingPathComponent(
//            AudioPlayerTests.testFileName
//        )
//    }
    var mixer = AVAudioMixerNode()
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
    }
    
    override func tearDown(){
        self.audioEngine.stop()
    }
}
