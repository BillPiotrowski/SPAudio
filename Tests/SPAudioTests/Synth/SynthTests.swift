import XCTest
@testable import SPAudio
import AVFoundation
import AudioKitLite

final class SynthTests: AudioSetupXCTTestCase {
    
    // MARK: TEST CONNECT
    func testConnect() throws {
        // ARRANGE
        let synth = Synth(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        
        // ACT
        try synth.connect()
        try audioEngine.start()
        
        // ASSERT
        XCTAssert(synth.isConnected)
        synth.disconnect()
    }
    
    
    // MARK: TEST DISCONNECT
    func testDisconnect() throws {
        // ARRANGE
        let synth = Synth(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        try synth.connect()
        try audioEngine.start()
        
        // ACT
        synth.disconnect()
        
        // ASSERT
        XCTAssert(!synth.isConnected)
    }
    
    // MARK: TEST PLAY
    func testPlay() throws {
        // ARRANGE
        let synth = Synth(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        try synth.connect()
        try audioEngine.start()
        
        // ACT
        synth.play(noteNumber: 64, velocity: 100)
        
        // ASSERT
        XCTAssert(synth.isPlaying)
        XCTAssert(!synth.nextOscillator.isPlaying)
        XCTAssert(synth.playingOscillatorsCount == 1)
        XCTAssert(synth.notPlayingOscillatorsCount == 3)
        XCTAssert(synth.firstNotPlaying != nil)
        synth.disconnect()
    }
    
    
    // MARK: TEST STOP
    func testStop() throws {
        // ARRANGE
        let noteNumber: MIDINoteNumber = 64
        let synth = Synth(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        try synth.connect()
        try audioEngine.start()
        synth.play(noteNumber: noteNumber, velocity: 100)
        
        // ACT
        synth.stop(noteNumber: noteNumber)
        
        // ASSERT
        XCTAssert(!synth.isPlaying)
        XCTAssert(synth.playingOscillatorsCount == 0)
        XCTAssert(synth.notPlayingOscillatorsCount == 4)
        XCTAssert(synth.firstNotPlaying != nil)
        synth.disconnect()
    }
    
    // MARK: TEST LOW TO HIGH SORT ORDER
    func testPitchSortOrder() throws {
        // ARRANGE
        let note1: MIDINoteNumber = 64
        let note2: MIDINoteNumber = 67
        let note3: MIDINoteNumber = 71
        let note4: MIDINoteNumber = 74
        let synth = Synth(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        try synth.connect()
        try audioEngine.start()
        
        // ACT
        synth.play(noteNumber: note1, velocity: 100)
        XCTAssert(synth.notPlayingOscillatorsCount == 3)
        XCTAssert(synth.playingOscillatorsCount == 1)
        synth.play(noteNumber: note2, velocity: 100)
        XCTAssert(synth.notPlayingOscillatorsCount == 2)
        XCTAssert(synth.playingOscillatorsCount == 2)
        synth.play(noteNumber: note3, velocity: 100)
        XCTAssert(synth.notPlayingOscillatorsCount == 1)
        XCTAssert(synth.playingOscillatorsCount == 3)
        synth.play(noteNumber: note4, velocity: 100)
        
        // ASSERT
        XCTAssert(synth.firstNotPlaying == nil)
        XCTAssert(synth.oscillatorsPlayingLowToHigh.count == 4)
        XCTAssert(synth.lowestOscillatorPlaying!.noteNumber == note1)
        XCTAssert(synth.highestOscillatorPlaying!.noteNumber == note4)
        synth.disconnect()
    }
    
    
    // MARK: TEST PLAY 5 NOTES IN A ROW
    func testPlayMult() throws {
        // ARRANGE
        let note1: MIDINoteNumber = 64
        let note2: MIDINoteNumber = 67
        let note3: MIDINoteNumber = 71
        let note4: MIDINoteNumber = 74
        let note5: MIDINoteNumber = 76
        let synth = Synth(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        try synth.connect()
        try audioEngine.start()
        
        // ACT
        synth.play(noteNumber: note5, velocity: 100)
        synth.play(noteNumber: note1, velocity: 100)
        synth.play(noteNumber: note2, velocity: 100)
        synth.play(noteNumber: note3, velocity: 100)
        synth.play(noteNumber: note4, velocity: 100)
        
        // ASSERT
        XCTAssert(synth.firstNotPlaying == nil)
        XCTAssert(synth.playingOscillatorsCount == 4)
        XCTAssert(synth.notPlayingOscillatorsCount == 0)
        XCTAssert(synth.highestOscillatorPlaying?.noteNumber == note4)
        XCTAssert(synth.isPlaying)
        synth.disconnect()
    }
    
    // MARK: TEST PLAY 2 NOTES IN A ROW
    func testPlayTwo() throws {
        // ARRANGE
        let note1: MIDINoteNumber = 64
        let note2: MIDINoteNumber = 67
        let synth = Synth(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        try synth.connect()
        try audioEngine.start()
        
        // ACT
        synth.play(noteNumber: note1, velocity: 100)
        synth.play(noteNumber: note2, velocity: 100)
        
        // ASSERT
        XCTAssert(synth.firstNotPlaying != nil)
        XCTAssert(synth.playingOscillatorsCount == 2)
        XCTAssert(synth.notPlayingOscillatorsCount == 2)
        XCTAssert(synth.isPlaying)
        synth.disconnect()
    }
    
    
    static var allTests = [
        ("testConnect", testConnect),
        ("testDisconnect", testDisconnect),
        ("testPlay", testPlay),
        ("testStop", testStop),
        ("testPlayMult", testPlayMult),
    ]
}
