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
    
//    func testAudioFile(){
//        let documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
//            let destinationFileUrl = documentsUrl.appendingPathComponent("downloadedFile.jpg")
//
//            //Create URL to the source file you want to download
//            let fileURL = URL(string: "https://s3.amazonaws.com/learn-swift/IMG_0001.JPG")
//
//            let sessionConfig = URLSessionConfiguration.default
//            let session = URLSession(configuration: sessionConfig)
//
//            let request = URLRequest(url:fileURL!)
//
//            let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
//                if let tempLocalUrl = tempLocalUrl, error == nil {
//                    // Success
//                    if let statusCode = (response as? HTTPURLResponse)?.statusCode {
//                        print("Successfully downloaded. Status code: \(statusCode)")
//                    }
//
//                    do {
//                        try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
//                    } catch (let writeError) {
//                        print("Error creating a file \(destinationFileUrl) : \(writeError)")
//                    }
//
//                } else {
//                    print("Error took place while downloading a file. Error description: %@", error?.localizedDescription);
//                }
//            }
//            task.resume()
//
//          }
//
//
//
//
//
//
//        let url = Bundle(for: type(of: self)).url(forResource: <#T##String?#>, withExtension: <#T##String?#>)
//            //.main.url(forResource: "/Tests/SPAudioTests/AudioMeter/TimedMeter/dialog", withExtension: ".mp3")
//
//
//        XCTAssertEqual(url, nil)
////         guard let dataURL = url, let data = try? Data(contentsOf: dataURL) else {
////             fatalError("Couldn't read data.json file") }
//    }

    static var allTests = [
        ("testAverage1", testAverage1),
        ("testAverage2", testAverage2),
    ]
}
