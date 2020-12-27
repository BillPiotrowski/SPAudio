import XCTest
@testable import SPAudio
import AVFoundation

final class AudioPlayerTests: XCTestCase {
    // MARK: DEFINE VARS
    private var audioEngine = AudioEngine()
    static let testFileName = "test.aiff"
    static let temporaryDirectory = FileManager.default.temporaryDirectory
    var testFileURL: URL {
        return AudioPlayerTests.temporaryDirectory.appendingPathComponent(
            AudioPlayerTests.testFileName
        )
    }
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
    
    // MARK: TEST: INIT
    func testAudioPlayerInit(){
        // ACT
        let audioPlayer = AudioPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [connectionPoint]
        )
        
        guard audioPlayer.avAudioPlayerNode.engine != nil
        else {
            XCTFail("Player node was node was not attached")
            return
        }
        
        guard case .standby = audioPlayer.playerState
        else {
            XCTFail("Initial state should be standby.")
            return
        }
        
        // ASSERT
        XCTAssertTrue(true)
    }
    
    // MARK: TEST LOAD
    func testPlayerLoad() throws {
        // GIVEN
        let audioPlayer = AudioPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [connectionPoint]
        )
        
        // WHEN
        try audioPlayer.load(self.testFileURL)
        
        // ASSERT
        guard case .cued = audioPlayer.playerState
        else {
            XCTFail("Incorrect state after loading.")
            return
        }
        
        XCTAssertTrue(audioPlayer.audioFile != nil)
    }
    
    // MARK: TEST: UNLOAD
    func testPlayerUnload() throws {
        // ARRANGE
        let audioPlayer = AudioPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [connectionPoint]
        )
        try audioPlayer.load(self.testFileURL)
        
        // ACT
        audioPlayer.unload()
        
        // ASSERT
        guard case .standby = audioPlayer.playerState
        else {
            XCTFail("Player state was not reset to standby")
            return
        }
        
        XCTAssertTrue(audioPlayer.audioFile == nil)
    }
    
    // MARK: TEST: CONNECT
    func testPlayerConnect() throws {
        let audioPlayer = AudioPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [connectionPoint]
        )
        try audioPlayer.load(self.testFileURL)
        try audioPlayer.connect()
        
        XCTAssertTrue(audioPlayer.isConnected)
    }
    
    // MARK: TEST: DISCONNECT
    func testPlayerDisconnect() throws {
        // ARRANGE
        let audioPlayer = AudioPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [connectionPoint]
        )
        try audioPlayer.load(self.testFileURL)
        try audioPlayer.connect()
        
        // ACT
        audioPlayer.disconnect()
        
        // ASSERT
        XCTAssertFalse(audioPlayer.isConnected)
    }
    
    // MARK: TEST: SCHEDULE FILE
    func testFileScheduled() throws {
        // ARRANGE
        let audioPlayer = AudioPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [connectionPoint]
        )
        try audioPlayer.load(self.testFileURL)
        try audioPlayer.connect()
        guard !audioPlayer.isScheduled
        else {
            XCTFail("Should be unscheduled.")
            return
        }
        
        // ACT
        try audioPlayer.scheduleAudioFile()
        
        // ASSERT
        XCTAssertTrue(audioPlayer.isScheduled)
    }
    
    // MARK: TEST: PLAY
    func testPlay() throws {
        // ARRANGE
        let audioPlayer = AudioPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [connectionPoint]
        )
        try audioPlayer.load(self.testFileURL)
        
        guard case .stopped = audioPlayer.audioTransportState.value
        else {
            XCTFail("State should be stopped.")
            return
        }
        
        guard !audioPlayer.isPlaying
        else {
            XCTFail("Should not be playing.")
            return
        }
        
        // ACT
        try audioPlayer.play()
        
        // ASSERT
        guard case .playing = audioPlayer.audioTransportState.value
        else {
            XCTFail("State should be playing.")
            return
        }
        guard !audioPlayer.isScheduled
        else {
            XCTFail("Should not be scheduled.")
            return
        }
        
        XCTAssertTrue(audioPlayer.isPlaying)
    }
    
    // MARK: TEST STOP
    func testStop() throws {// ARRANGE
        let audioPlayer = AudioPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [connectionPoint]
        )
        try audioPlayer.load(self.testFileURL)
        try audioPlayer.play()
        
        // ACT
        audioPlayer.stop()
        
        // ASSERT
        guard case .stopped = audioPlayer.audioTransportState.value
        else {
            XCTFail("State should be stopped.")
            return
        }
        guard !audioPlayer.isScheduled
        else {
            XCTFail("Should not be scheduled.")
            return
        }
        
        XCTAssertFalse(audioPlayer.isPlaying)
    }
    
    // MARK: TEST UNLOAD FROM PLAYING
    func testUnloadFromPlaying() throws {
        // ARRANGE
        let audioPlayer = AudioPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [connectionPoint]
        )
        try audioPlayer.load(self.testFileURL)
        try audioPlayer.play()
        
        // ACT
        audioPlayer.unload()
        
        // ASSERT
        guard case .standby = audioPlayer.playerState
        else {
            XCTFail("Player state was not reset to standby")
            return
        }
        
        guard !audioPlayer.isConnected
        else {
            XCTFail("Player should be disconnected.")
            return
        }
        
        XCTAssertTrue(audioPlayer.audioFile == nil)
    }
    
    // MARK: TEST LOAD FROM PLAYING
    // MOST EXTREME SCENERIO
    func testLoadFromPlaying() throws {
        // ARRANGE
        let audioPlayer = AudioPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [connectionPoint]
        )
        try audioPlayer.load(self.testFileURL)
        try audioPlayer.play()
        
        // ACT
        try audioPlayer.load(self.testFileURL)
        
        // ASSERT
        guard case .cued = audioPlayer.playerState
        else {
            XCTFail("Incorrect state after loading.")
            return
        }
        
        XCTAssertTrue(audioPlayer.audioFile != nil)
    }
    
    
    static var allTests = [
        ("testAudioPlayerInit", testAudioPlayerInit),
        ("testPlayerLoad", testPlayerLoad),
        ("testPlayerUnload", testPlayerUnload),
        ("testPlayerConnect", testPlayerConnect),
        ("testPlayerDisconnect", testPlayerDisconnect),
        ("testFileScheduled", testFileScheduled),
        ("testPlay", testPlay),
        ("testStop", testStop),
        ("testUnloadFromPlaying", testUnloadFromPlaying),
        ("testLoadFromPlaying", testLoadFromPlaying),
    ]
}

