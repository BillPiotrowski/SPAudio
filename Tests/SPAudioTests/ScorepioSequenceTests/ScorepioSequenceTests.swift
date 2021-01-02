import XCTest
@testable import SPAudio
import AVFoundation
import AudioKit

final class ScorepioSequenceTests: XCTestCase {
    static let testFileName = "test.aiff"
    static let temporaryDirectory = FileManager.default.temporaryDirectory
    var testFileURL: URL {
        return AudioPlayerTests.temporaryDirectory.appendingPathComponent(
            AudioPlayerTests.testFileName
        )
    }
    private var audioEngine = SPAudio.AudioEngine()
    private var mixer = AVAudioMixerNode()
    var outputConnectionPoint: AVAudioConnectionPoint {
        return AVAudioConnectionPoint(node: mixer, bus: 0)
    }
    var fxConnectionPoint: AVAudioConnectionPoint {
        return AVAudioConnectionPoint(node: mixer, bus: 1)
    }
    
    override func setUpWithError() throws {
        let audioEngine = SPAudio.AudioEngine()
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
//        try? FileManager.default.removeItem(at: self.testFileURL)
    }
    
    // MARK: TEST INIT
    func testInit() throws {
        // ACT
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        
        // ASSERT
        try ScorepioSequenceTests.allNodesAttached(
            engine: audioEngine.engine,
            sequence: sequence
        )
        XCTAssertTrue(
            sequence.stemPlayers.count == AudioSequencer.trackCount
        )
    }
    
    /// Throws if any of the avAudioNodes are not attached to the avAudioEngine.
    static func allNodesAttached(
        engine: AVAudioEngine,
        sequence: AudioSequencer
    ) throws {
        guard sequence.mainMaster.engine === engine
        else { throw NSError(
            domain: "mainMaster not attached.", code: 1, userInfo: nil
        )}
        guard sequence.fxMaster.engine === engine
        else { throw NSError(
            domain: "fxMaster not attached.", code: 1, userInfo: nil
        )}
        guard sequence.outputMixer.engine === engine
        else { throw NSError(
            domain: "outputMixer not attached.", code: 1, userInfo: nil
        )}
        guard sequence.stemMixer.engine === engine
        else { throw NSError(
            domain: "stemMixer not attached.", code: 1, userInfo: nil
        )}
        guard sequence.stemFXMixer.engine === engine
        else { throw NSError(
            domain: "stemFXMixer not attached.", code: 1, userInfo: nil
        )}
        guard sequence.synth.avAudioNode.engine === engine
        else { throw NSError(
            domain: "synth not attached.", code: 1, userInfo: nil
        )}
    }
    
    // MARK: TEST: SIMULATED LOAD
    func testLoad() throws {
        // ARRANGE
        let usesSynth: Bool = true
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        
        // ACT
        for stem in sequence.stemPlayers {
            try stem.load(audioURL: self.testFileURL)
        }
        sequence.loadingComplete(usesSynth: usesSynth)
        
        // ASSERT
        XCTAssert(
            sequence.usesSynth == usesSynth &&
            sequence.activeStemPlayers.count == sequence.stemPlayers.count &&
            sequence.sequencerState == .cued
        )
    }
    
    // MARK: TEST SETTINGS CHANGE
    func testSettingsChange() throws {
        // ARRANGE
        let newSettings = AudioSequencer.Settings(fxSend: 0.4, volume: 0.9)
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        for stem in sequence.stemPlayers {
            try stem.load(audioURL: self.testFileURL)
        }
        sequence.loadingComplete()
        
        // ACT
        sequence.set(settings: newSettings)
        
        // ASSERT
        XCTAssert(newSettings == sequence.settings)
    }
    
    // MARK: TEST UNLOAD / RESET
    func testUnload() throws {
        // ARRANGE
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        for stem in sequence.stemPlayers {
            try stem.load(audioURL: self.testFileURL)
        }
        sequence.loadingComplete(usesSynth: true)
        
        // ACT
        sequence.reset()
        
        // ASSERT
        XCTAssert(
            try ScorepioSequenceTests.isSequencerReset(sequence: sequence) &&
            sequence.settings == AudioSequencer.defaultSettings &&
            sequence.masterVolume == AudioSequencer.masterVolumeDefault
        )
    }
    
    static func isSequencerReset(sequence: AudioSequencer) throws -> Bool {
        guard sequence.sequencerState == .empty
        else { throw
            NSError(domain: "State is not empty", code: 1, userInfo: nil)
        }
        for stem in sequence.stemPlayers {
            guard stem.audioTrackState == .empty
            else { throw
                NSError(domain: "Stem is not empty", code: 1, userInfo: nil)
            }
        }
        guard sequence.usesSynth == AudioSequencer.usesSynthDefault
        else { throw
            NSError(domain: "usesSynth var not reset to default.", code: 1, userInfo: nil)
        }
        guard sequence.activeStemPlayers.count == 0
        else { throw
            NSError(domain: "Active stem players should be empty", code: 1, userInfo: nil)
        }
        guard sequence.sequencer.trackCount == 0
        else { throw
            NSError(domain: "Sequencer track count should be zero.", code: 1, userInfo: nil)
        }
        guard sequence.sequencer.length.beats == 0
        else { throw
            NSError(domain: "Sequencer length should be zero.", code: 1, userInfo: nil)
        }
        return true
    }
    
    // MARK: TEST CONNECT w/ Synth
    func testConnect1() throws {
        // ARRANGE
        let usesSynth = true
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        for stem in sequence.stemPlayers {
            try stem.load(audioURL: self.testFileURL)
        }
        sequence.loadingComplete(usesSynth: usesSynth)
        
        // ACT
        try sequence.connect()
        
        // ASSERT
        let _ = try ScorepioSequenceTests.isConnection(sequence: sequence)
        XCTAssert(sequence.isConnected)
    }
    
    // MARK: TEST CONNECT w/o Synth
    func testConnect2() throws {
        // ARRANGE
        let usesSynth = false
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        for stem in sequence.stemPlayers {
            try stem.load(audioURL: self.testFileURL)
        }
        sequence.loadingComplete(usesSynth: usesSynth)
        
        // ACT
        try sequence.connect()
        
        // ASSERT
        let _ = try ScorepioSequenceTests.isConnection(sequence: sequence)
        XCTAssert(sequence.isConnected)
    }
    
    static func isConnection(sequence: AudioSequencer) throws -> Bool {
        guard sequence.mainMaster.isOutputConnected else {
            throw NSError(domain: "mainMaster not connected", code: 1, userInfo: nil)
        }
        guard sequence.fxMaster.isOutputConnected else {
            throw NSError(domain: "fxMaster not connected", code: 1, userInfo: nil)
        }
        guard sequence.outputMixer.isOutputConnected else {
            throw NSError(domain: "outputMixer not connected", code: 1, userInfo: nil)
        }
        guard sequence.stemMixer.isOutputConnected else {
            throw NSError(domain: "stemMixer not connected", code: 1, userInfo: nil)
        }
        guard sequence.stemFXMixer.isOutputConnected else {
            throw NSError(domain: "stemFXMixer not connected", code: 1, userInfo: nil)
        }
        guard sequence.usesSynth == sequence.synth.avAudioNode.isOutputConnected
        else {
            throw NSError(domain: "synth connection does not match usesSynth.", code: 1, userInfo: nil)
        }
        for stemPlayer in sequence.activeStemPlayers {
            guard stemPlayer.isConnected else {
                throw NSError(domain: "stem player not connected.", code: 1, userInfo: nil)
            }
        }
        return true
    }
    
    // MARK: TEST DISCONNECT
    func testDisconnect() throws {
        // ARRANGE
        let usesSynth = true
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        for stem in sequence.stemPlayers {
            try stem.load(audioURL: self.testFileURL)
        }
        sequence.loadingComplete(usesSynth: usesSynth)
        try sequence.connect()
        
        // ACT
        sequence.disconnect()
        
        // ASSERT
        let _ = try ScorepioSequenceTests.isDisconnected(sequence: sequence)
        XCTAssert(!sequence.isConnected)
    }
    
    static func isDisconnected(sequence: AudioSequencer) throws -> Bool {
        guard !sequence.mainMaster.isOutputConnected else {
            throw NSError(domain: "mainMaster should not be connected", code: 1, userInfo: nil)
        }
        guard !sequence.fxMaster.isOutputConnected else {
            throw NSError(domain: "fxMaster should not be connected", code: 1, userInfo: nil)
        }
        guard !sequence.outputMixer.isOutputConnected else {
            throw NSError(domain: "outputMixer should not be connected", code: 1, userInfo: nil)
        }
        guard !sequence.stemMixer.isOutputConnected else {
            throw NSError(domain: "stemMixer should not be connected", code: 1, userInfo: nil)
        }
        guard !sequence.stemFXMixer.isOutputConnected else {
            throw NSError(domain: "stemFXMixer should not be connected", code: 1, userInfo: nil)
        }
        guard !sequence.synth.avAudioNode.isOutputConnected else {
            throw NSError(domain: "synth should not be connected", code: 1, userInfo: nil)
        }
        for stemPlayer in sequence.stemPlayers {
            guard !stemPlayer.isConnected else {
                throw NSError(domain: "stem player should not be connected.", code: 1, userInfo: nil)
            }
        }
        return true
    }

    // EVENTUALLY RUN TEST FROM PLAYING
    // MARK: TEST UNLOAD FROM CONNECTED
    func testUnloadFromConnected() throws {
        // ARRANGE
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        for stem in sequence.stemPlayers {
            try stem.load(audioURL: self.testFileURL)
        }
        sequence.loadingComplete()
        try sequence.connect()
        
        // ACT
        sequence.reset()
        
        // ASSERT
        XCTAssert(
            try ScorepioSequenceTests.isSequencerReset(sequence: sequence) &&
            sequence.settings == AudioSequencer.defaultSettings &&
            sequence.masterVolume == AudioSequencer.masterVolumeDefault
        )
    }
    
    // MARK: TEST PREPARE TO PLAY
    // The play tests are not that thorough.
    func testPrepareToPlay() throws {
        // ARRANGE
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        let midiSequence = sequence.sequencer
        let duration = Duration(seconds: 10)
        midiSequence.setLength(duration)
        let _ = midiSequence.newTrack("Conductor")
        for stem in sequence.stemPlayers {
            try stem.load(audioURL: self.testFileURL)
            let _ = midiSequence.newTrack()
        }
        sequence.loadingComplete()
        
        // VERIFY
        guard !sequence.isPreparedToPlay else {
            throw NSError(domain: "Should not be prepared", code: 1, userInfo: nil)
        }
        
        // ACT
        try sequence.prepareToPlay()
        
        let _ = try ScorepioSequenceTests.isConnection(sequence: sequence)
        XCTAssert(sequence.isPreparedToPlay)
    }
    
    // MARK: TEST PLAY
    func testPlay() throws {
        // ARRANGE
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        let midiSequence = sequence.sequencer
        let duration = Duration(seconds: 10)
        midiSequence.setLength(duration)
        let _ = midiSequence.newTrack("Conductor")
        for stem in sequence.stemPlayers {
            try stem.load(audioURL: self.testFileURL)
            let _ = midiSequence.newTrack()
        }
        sequence.loadingComplete()
        try sequence.connect()
        
        // VERIFY
        guard sequence.transportState == .stopped else {
            throw NSError(domain: "Should be stopped.", code: 1, userInfo: nil)
        }
        
        // ACT
        try sequence.play()
        
        XCTAssert(sequence.isPlaying && sequence.transportState == .playing)
    }
    
    // MARK: TEST STOP
    func testStop() throws {
        // ARRANGE
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        let midiSequence = sequence.sequencer
        let duration = Duration(seconds: 10)
        midiSequence.setLength(duration)
        let _ = midiSequence.newTrack("Conductor")
        for stem in sequence.stemPlayers {
            try stem.load(audioURL: self.testFileURL)
            let _ = midiSequence.newTrack()
        }
        sequence.loadingComplete()
        try sequence.connect()
        try sequence.play()
        
        // ACT
        sequence.stop()
        
        // ASSERT
        XCTAssert(
            sequence.isPlaying == false &&
            sequence.transportState == .stopped &&
            midiSequence.currentPosition == Duration(beats: 0)
        )
    }
    
    // MARK: PLAY WITHOUT MIDI SEQ
    // KNOWN ISSUE WHEN SEQ HAS NO LENGTH, !isPlaying, but state is .playing
    func testPlayNoSeq() throws {
        // ARRANGE
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        sequence.loadingComplete()
        
        // ACT
        try sequence.play()
        
        XCTAssert(!sequence.isPlaying)
    }
    
    // MARK: TEST RESET FROM PLAYING
    func testResetFromPlaying() throws {
        // ARRANGE
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        let midiSequence = sequence.sequencer
        let duration = Duration(seconds: 10)
        midiSequence.setLength(duration)
        let _ = midiSequence.newTrack("Conductor")
        sequence.loadingComplete()
        try sequence.play()
        
        // ACT
        sequence.reset()
        
        // ASSERT
        XCTAssert(
            try ScorepioSequenceTests.isSequencerReset(sequence: sequence) &&
            sequence.settings == AudioSequencer.defaultSettings &&
            sequence.masterVolume == AudioSequencer.masterVolumeDefault
        )
        
    }
    
    // SOME OF THIS SHOULD BE HANDLED BY WPAudio wrappers when that is created.
    // MARK: CONNECT WHILE CONNECTED
    func testConnectWhileConnected() throws {
        // ARRANGE
        let usesSynth = true
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        for stem in sequence.stemPlayers {
            try stem.load(audioURL: self.testFileURL)
        }
        sequence.loadingComplete(usesSynth: usesSynth)
        try sequence.connect()
        
        // ACT
        // ASSERT
        XCTAssertThrowsError(try sequence.connect())
    }
    
    // MARK: TEST DISCONNECT WHILE DISCONNECTED
    func testDisconnectWhileDisconnected() throws {
        // ARRANGE
        let usesSynth = true
        let sequence = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        for stem in sequence.stemPlayers {
            try stem.load(audioURL: self.testFileURL)
        }
        sequence.loadingComplete(usesSynth: usesSynth)
        try sequence.connect()
        sequence.disconnect()
        
        // ACT
        sequence.disconnect()
        
        // ASSERT
        let _ = try ScorepioSequenceTests.isDisconnected(sequence: sequence)
        XCTAssert(!sequence.isConnected)
        
    }
    
    // MARK: TEST MEMORY LEAK
    func testMemoryLeak() throws {
        // ARRANGE
        var sequence: AudioSequencer? = AudioSequencer(
            audioEngine: self.audioEngine,
            playerConnectionPoint: self.outputConnectionPoint,
            fxConnectionPoint: self.fxConnectionPoint
        )
        let midiSequence = sequence!.sequencer
        let duration = Duration(seconds: 10)
        midiSequence.setLength(duration)
        let _ = midiSequence.newTrack("Conductor")
        for stem in sequence!.stemPlayers {
            try stem.load(audioURL: self.testFileURL)
            let _ = midiSequence.newTrack()
        }
        sequence!.loadingComplete()
        try sequence!.connect()
        try sequence!.play()
        weak var leakRef = sequence
        
        // ACT
        sequence = nil
        
        // ASSERT
        XCTAssert(leakRef == nil)
    }
    
    
    
    static var allTests = [
        ("testInit", testInit),
        ("testInit", testInit),
        ("testLoad", testLoad),
        ("testSettingsChange", testSettingsChange),
        ("testUnload", testUnload),
        ("testConnect1", testConnect1),
        ("testConnect2", testConnect2),
        ("testDisconnect", testDisconnect),
        ("testUnloadFromConnected", testUnloadFromConnected),
        ("testPrepareToPlay", testPrepareToPlay),
        ("testPlay", testPlay),
        ("testStop", testStop),
        ("testPlayNoSeq", testPlayNoSeq),
        ("testResetFromPlaying", testResetFromPlaying),
        ("testConnectWhileConnected", testConnectWhileConnected),
        ("testDisconnectWhileDisconnected", testDisconnectWhileDisconnected),
        ("testMemoryLeak", testMemoryLeak),
    ]
}
