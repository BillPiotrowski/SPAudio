import XCTest
@testable import SPAudio
import AVFoundation

final class OscillatorAndVCATests: AudioSetupXCTTestCase {
    
    // MARK: TEST CONNECT
    func testConnect() throws {
        // ARRANGE
        let vca = VCA(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        
        // ACT
        try vca.connect()
        try audioEngine.start()
        
        // ASSERT
        XCTAssert(vca.isConnected)
        vca.disconnect()
    }
    
    // MARK: TEST DISCONNECT
    func testDisconnect() throws {
        // ARRANGE
        let vca = VCA(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        try vca.connect()
        try audioEngine.start()
        
        // ACT
        vca.disconnect()
        
        // ASSERT
        XCTAssert(!vca.isConnected)
        vca.disconnect()
    }
    
    // MARK: TEST PLAY
    func testPlay() throws {
        // ARRANGE
        let vca = VCA(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        try vca.connect()
        try audioEngine.start()
        
        // ACT
        try vca.play()
        
        // ASSERT
        XCTAssert(vca.isPlaying)
        vca.disconnect()
    }
    
    // MARK: TEST STOP
    func testStop() throws {
        // ARRANGE
        let vca = VCA(
            wire: self.connectionPoint,
            audioEngine: self.audioEngine
        )
        try vca.connect()
        try audioEngine.start()
        try vca.play()
        
        // ACT
        vca.stop()
        
        // ASSERT
        XCTAssert(!vca.isPlaying)
        vca.disconnect()
    }
    
    static var allTests = [
        ("testConnect", testConnect),
        ("testDisconnect", testDisconnect),
        ("testPlay", testPlay),
        ("testStop", testStop),
    ]
}
