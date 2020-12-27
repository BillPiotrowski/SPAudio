import XCTest
@testable import SPAudio

final class MeterReadingArrayTests: XCTestCase {
    func testAverage1() {
        // GIVEN
        let array: [Float] = [1,2,3,4,5]
        let meterReadingArray = MeterReadingArray(meterArray: array)
        
        // THEN
        XCTAssertEqual(meterReadingArray.average, 3)
    }
    
    func testAverage2() {
        // GIVEN
        let array: [Float] = [6,7,5,8,4,9]
        let meterReadingArray = MeterReadingArray(meterArray: array)
        
        // THEN
        XCTAssertEqual(meterReadingArray.average, 6.5)
    }

    static var allTests = [
        ("testAverage1", testAverage1)
        ("testAverage2", testAverage2),
    ]
}
