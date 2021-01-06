import XCTest
@testable import SPAudio
import AVFoundation

final class VCATests: AudioSetupXCTTestCase {
    // MARK: TEST CONNECT
    func testConnect() throws {
        // ARRANGE
        let combo = OscillatorAndVCA(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        
        // ACT
        try combo.connect()
        try audioEngine.start()
        
        // ASSERT
        XCTAssert(combo.isConnected)
        combo.disconnect()
    }
    
    
    // MARK: TEST DISCONNECT
    func testDisconnect() throws {
        // ARRANGE
        let combo = OscillatorAndVCA(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        try combo.connect()
        try audioEngine.start()
        
        // ACT
        combo.disconnect()
        
        // ASSERT
        XCTAssert(!combo.isConnected)
    }
    
    // MARK: TEST PLAY
    func testPlay() throws {
        // ARRANGE
        let combo = OscillatorAndVCA(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        try combo.connect()
        try audioEngine.start()
        
        // ACT
        combo.play(noteNumber: 64, velocity: 100)
        
        // ASSERT
        XCTAssert(combo.isPlaying)
        combo.disconnect()
    }
    
    
    // MARK: TEST STOP
    func testStop() throws {
        // ARRANGE
        let combo = OscillatorAndVCA(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        try combo.connect()
        try audioEngine.start()
        combo.play(noteNumber: 64, velocity: 100)
        
        // ACT
        combo.stop()
        
        // ASSERT
        XCTAssert(!combo.isPlaying)
        combo.disconnect()
    }
    
    
    // MARK: TEST PLAY TWO NOTES IN A ROW
    func testPlayTwice() throws {
        // ARRANGE
        let combo = OscillatorAndVCA(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        try combo.connect()
        try audioEngine.start()
        combo.play(noteNumber: 64, velocity: 100)
        combo.play(noteNumber: 67, velocity: 100)
        
        // ACT
        combo.play(noteNumber: 67, velocity: 100)
        
        // ASSERT
        XCTAssert(combo.isPlaying)
//        combo.disconnect()
    }
    
    
    static var allTests = [
        ("testConnect", testConnect),
    ]
}
