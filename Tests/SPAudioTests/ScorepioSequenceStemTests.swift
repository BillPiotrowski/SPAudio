import XCTest
@testable import SPAudio
import AVFoundation

final class ScorepioSequenceStemTests: XCTestCase {
    static let testFileName = "test.aiff"
    static let temporaryDirectory = FileManager.default.temporaryDirectory
    var testFileURL: URL {
        return AudioPlayerTests.temporaryDirectory.appendingPathComponent(
            AudioPlayerTests.testFileName
        )
    }
    private var audioEngine = AudioEngine()
    private var mixer = AVAudioMixerNode()
    var outputConnectionPoint: AVAudioConnectionPoint {
        return AVAudioConnectionPoint(node: mixer, bus: 0)
    }
    var fxConnectionPoint: AVAudioConnectionPoint {
        return AVAudioConnectionPoint(node: mixer, bus: 1)
    }
    
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
    
    // MARK: TEST INIT
    func testInit(){
        // ACT
        let sequenceStem = StemPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [self.outputConnectionPoint],
            fxConnectionPoints: [self.fxConnectionPoint],
            stemIndex: 0
        )
        
        // ASSERT
        guard sequenceStem.outputMixer.engine === self.audioEngine.engine
        else {
            XCTFail("outputMixer node was node was not attached")
            return
        }
        guard sequenceStem.pitchAU.engine === self.audioEngine.engine
        else {
            XCTFail("pitchAU node was node was not attached")
            return
        }
        guard sequenceStem.fxMixer.engine === self.audioEngine.engine
        else {
            XCTFail("fxMixer node was node was not attached")
            return
        }
        guard sequenceStem.inputMixer.engine === self.audioEngine.engine
        else {
            XCTFail("inputMixer node was node was not attached")
            return
        }
        
        XCTAssertTrue(true)
        
    }
    
    // MARK: TEST LOAD
    func testLoad() throws {
        // ARRANGE
        let sequenceStem = StemPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [self.outputConnectionPoint],
            fxConnectionPoints: [self.fxConnectionPoint],
            stemIndex: 0
        )
        
        // ACT
        try sequenceStem.load(audioURL: self.testFileURL)
        
        // ASSERT
        guard case .cued = sequenceStem.audioTrackState
        else {
            XCTFail("State should be cued.")
            return
        }
        XCTAssertTrue(sequenceStem.audioPlayer.audioFile != nil)
    }
    
    // MARK: TEST UNLOAD
    func testUnload() throws {
        // ARRANGE
        let sequenceStem = StemPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [self.outputConnectionPoint],
            fxConnectionPoints: [self.fxConnectionPoint],
            stemIndex: 0
        )
        try sequenceStem.load(audioURL: self.testFileURL)
        
        // ACT
        sequenceStem.unload()
        
        // ASSERT
        guard case .empty = sequenceStem.audioTrackState
        else {
            XCTFail("State should be empty.")
            return
        }
        XCTAssertTrue(sequenceStem.audioPlayer.audioFile == nil)
        
    }
    
    // MARK: TEST CONNECT (no pitch AU)
    func testConnect1() throws {
        // ARRANGE
        let sequenceStem = StemPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [self.outputConnectionPoint],
            fxConnectionPoints: [self.fxConnectionPoint],
            stemIndex: 0
        )
        try sequenceStem.load(audioURL: self.testFileURL)
        
        // ACT
        try sequenceStem.connect()
        
        // ASSERT
        guard sequenceStem.outputMixer.isOutputConnected else {
            XCTFail("outputMixer is not connected.")
            return
        }
        guard sequenceStem.fxMixer.isOutputConnected else {
            XCTFail("fxMixer is not connected.")
            return
        }
        guard sequenceStem.inputMixer.isOutputConnected else {
            XCTFail("inputMixer is not connected.")
            return
        }
        guard sequenceStem.audioPlayer.isConnected else {
            XCTFail("audioPlayer is not connected.")
            return
        }
        guard !sequenceStem.pitchAU.isOutputConnected else {
            XCTFail("pitchModulation should not be connected.")
            return
        }
        XCTAssertTrue(sequenceStem.isConnected)
        
    }
    
    // MARK: TEST CONNECT (with pitch AU)
    func testConnect2() throws {
        // ARRANGE
        let sequenceStem = StemPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [self.outputConnectionPoint],
            fxConnectionPoints: [self.fxConnectionPoint],
            stemIndex: 0
        )
        try sequenceStem.load(
            audioURL: self.testFileURL,
            properties: nil,
            pitchModulation: true
        )
        
        // ACT
        try sequenceStem.connect()
        
        // ASSERT
        guard sequenceStem.outputMixer.isOutputConnected else {
            XCTFail("outputMixer is not connected.")
            return
        }
        guard sequenceStem.fxMixer.isOutputConnected else {
            XCTFail("fxMixer is not connected.")
            return
        }
        guard sequenceStem.inputMixer.isOutputConnected else {
            XCTFail("inputMixer is not connected.")
            return
        }
        guard sequenceStem.audioPlayer.isConnected else {
            XCTFail("audioPlayer is not connected.")
            return
        }
        guard sequenceStem.pitchAU.isOutputConnected else {
            XCTFail("pitchModulation should not be connected.")
            return
        }
        XCTAssertTrue(sequenceStem.isConnected)
        
    }
    
    // MARK: DISCONNECT no pitch AU
    func testDisconnect1() throws {
        // ARRANGE
        let sequenceStem = StemPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [self.outputConnectionPoint],
            fxConnectionPoints: [self.fxConnectionPoint],
            stemIndex: 0
        )
        try sequenceStem.load(audioURL: self.testFileURL)
        try sequenceStem.connect()
        
        // ACT
        sequenceStem.disconnect()
        
        // ASSERT
        guard !sequenceStem.outputMixer.isOutputConnected else {
            XCTFail("outputMixer is still connected.")
            return
        }
        guard !sequenceStem.fxMixer.isOutputConnected else {
            XCTFail("fxMixer is still connected.")
            return
        }
        guard !sequenceStem.inputMixer.isOutputConnected else {
            XCTFail("inputMixer is still connected.")
            return
        }
        guard !sequenceStem.audioPlayer.isConnected else {
            XCTFail("audioPlayer is still connected.")
            return
        }
        guard !sequenceStem.pitchAU.isOutputConnected else {
            XCTFail("outputMixer is connected.")
            return
        }
        XCTAssertTrue(!sequenceStem.isConnected)
    }
    
    // MARK: DISCONNECT w/ pitch AU
    func testDisconnect2() throws {
        // ARRANGE
        let sequenceStem = StemPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [self.outputConnectionPoint],
            fxConnectionPoints: [self.fxConnectionPoint],
            stemIndex: 0
        )
        try sequenceStem.load(
            audioURL: self.testFileURL,
            properties: nil,
            pitchModulation: true
        )
        try sequenceStem.connect()
        
        // ACT
        sequenceStem.disconnect()
        
        // ASSERT
        guard !sequenceStem.outputMixer.isOutputConnected else {
            XCTFail("outputMixer is still connected.")
            return
        }
        guard !sequenceStem.fxMixer.isOutputConnected else {
            XCTFail("fxMixer is still connected.")
            return
        }
        guard !sequenceStem.inputMixer.isOutputConnected else {
            XCTFail("inputMixer is still connected.")
            return
        }
        guard !sequenceStem.audioPlayer.isConnected else {
            XCTFail("audioPlayer is still connected.")
            return
        }
        guard !sequenceStem.pitchAU.isOutputConnected else {
            XCTFail("outputMixer is still connected.")
            return
        }
        XCTAssertTrue(!sequenceStem.isConnected)
    }
    
    // MARK: TEST PLAY
    func testPlay() throws {
        // ARRANGE
        let sequenceStem = StemPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [self.outputConnectionPoint],
            fxConnectionPoints: [self.fxConnectionPoint],
            stemIndex: 0
        )
        try sequenceStem.load(
            audioURL: self.testFileURL
        )
        try sequenceStem.connect()
        
        // ACT
        try sequenceStem.play()
        
        // ASSERT
        XCTAssertTrue(
            sequenceStem.isPlaying && sequenceStem.audioPlayer.isPlaying
        )
    }
    
    // MARK: TEST STOP
    func testStop() throws {
        // ARRANGE
        let sequenceStem = StemPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [self.outputConnectionPoint],
            fxConnectionPoints: [self.fxConnectionPoint],
            stemIndex: 0
        )
        try sequenceStem.load(
            audioURL: self.testFileURL
        )
        try sequenceStem.connect()
        try sequenceStem.play()
        
        // ACT
        sequenceStem.stop()
        
        // ASSERT
        XCTAssertTrue(
            !sequenceStem.isPlaying && !sequenceStem.audioPlayer.isPlaying
        )
    }
    
    // MARK: TEST DEFAULTS ON INIT
    // Float rounding errors in pan -> pan control may cause failure.
    func testDefaultsOnInit() {
        // ACT
        let sequenceStem = StemPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [self.outputConnectionPoint],
            fxConnectionPoints: [self.fxConnectionPoint],
            stemIndex: 0
        )
        
        // ASSERT
        XCTAssertTrue(sequenceStem.settings == StemPlayer.defaultSettings)
    }
    
    // MARK: TEST SETTINGS ON LOAD
    // Float rounding errors in pan -> pan control may cause failure.
    func testSettingsOnLoad() throws {
        // ARRANGE
        let customSettings = StemPlayer.Settings(
            volume: 0.636,
            pan: -0.23,
            isMuted: true,
            fxSend: 0.125,
            loop: true,
            pitchRate: 0.231
        )
        let sequenceStem = StemPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [self.outputConnectionPoint],
            fxConnectionPoints: [self.fxConnectionPoint],
            stemIndex: 0
        )
        
        // ACT
        try sequenceStem.load(
            audioURL: self.testFileURL,
            properties: customSettings.properties
        )
        
        // ASSERT
        print("SEQUENCE SETTINGS")
        print(sequenceStem.settings)
        XCTAssertTrue(sequenceStem.settings == customSettings)
    }
    
    // MARK: TEST PAN to PAN CONTROL
    // Rounding errors in pan -> pan control may cause failure.
    func testPanToPanControl(){
        // ARRANGE
        let pan: Pan = 0
        
        // ACT
        let panControl = StemPlayer.Settings.panControl(from: pan)
        
        // ASSERT
        XCTAssertTrue(panControl == 0.5)
    }
    
    // MARK: TEST PAN CONTROL to PAN
    func testPanControlToPan(){
        // ARRANGE
        let panControl: PanControl = 0.25
        
        // ACT
        let pan = StemPlayer.Settings.pan(from: panControl)
        
        // ASSERT
        XCTAssertTrue(pan == -0.5)
    }
    
    // MARK: TEST REVERT
    func testRevert() throws {
        // ARRANGE
        let customSettings = StemPlayer.Settings(
            volume: 0.636,
            pan: -0.23,
            isMuted: true,
            fxSend: 0.125,
            loop: true,
            pitchRate: 0.231
        )
        let sequenceStem = StemPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [self.outputConnectionPoint],
            fxConnectionPoints: [self.fxConnectionPoint],
            stemIndex: 0
        )
        try sequenceStem.load(
            audioURL: self.testFileURL,
            settings: customSettings,
            pitchModulation: true
        )
        
        // ACT
        sequenceStem.revertToDefaultSettings()
        
        // ASSERT
        guard !sequenceStem.pitchModulation else {
            XCTFail("pitch modulation was not reset.")
            return
        }
        XCTAssertTrue(sequenceStem.settings == StemPlayer.defaultSettings)
    }
    
    // MARK: TEST: UNLOAD FROM PLAYING
    func testUnloadFromPlaying() throws {
        // ARRANGE
        let sequenceStem = StemPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [self.outputConnectionPoint],
            fxConnectionPoints: [self.fxConnectionPoint],
            stemIndex: 0
        )
        try sequenceStem.load(
            audioURL: self.testFileURL
        )
        try sequenceStem.play()
        
        // ACT
        sequenceStem.unload()
        
        // ASSERT
        guard case .empty = sequenceStem.audioTrackState
        else {
            XCTFail("State should be empty.")
            return
        }
        XCTAssertTrue(sequenceStem.audioPlayer.audioFile == nil)
    }
    
    // MARK: TEST MEMORY LEAK
    func testMemoryLeak() throws {
        // ARRANGE
        var sequenceStem: StemPlayer? = StemPlayer(
            audioEngine: self.audioEngine,
            outputConnectionPoints: [self.outputConnectionPoint],
            fxConnectionPoints: [self.fxConnectionPoint],
            stemIndex: 0
        )
        try sequenceStem!.load(
            audioURL: self.testFileURL
        )
        try sequenceStem!.play()
        weak var leakRef = sequenceStem
        
        // ACT
        sequenceStem = nil
        
        // ASSERT
        XCTAssertTrue(leakRef == nil)
    }
    
    static var allTests = [
        ("testInit", testInit),
        ("testLoad", testLoad),
        ("testUnload", testUnload),
        ("testConnect1", testConnect1),
        ("testConnect2", testConnect2),
        ("testDisconnect1", testDisconnect1),
        ("testDisconnect2", testDisconnect2),
        ("testPlay", testPlay),
        ("testStop", testStop),
        ("testDefaultsOnInit", testDefaultsOnInit),
        ("testSettingsOnLoad", testSettingsOnLoad),
        ("testPanToPanControl", testPanToPanControl),
        ("testPanControlToPan", testPanControlToPan),
        ("testRevert", testRevert),
        ("testUnloadFromPlaying", testUnloadFromPlaying),
        ("testMemoryLeak", testMemoryLeak),
    ]
}
