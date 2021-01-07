//
//  BufferReading.swift
//  Scorepio
//
//  Created by William Piotrowski on 1/22/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import AVFoundation


/// Takes a buffer reading and calculates the decibel level.
internal struct BufferReading {
    internal let absoluteMinDb: Decibel
    internal let channelDataValueArray: [Float]
    internal let frameLength: AVAudioFrameCount
    
    init(
        channelDataValueArray: [Float],
        frameLength: AVAudioFrameCount,
        absoluteMinDb: Float? = nil
    ){
        self.channelDataValueArray = channelDataValueArray
        self.frameLength = frameLength
        self.absoluteMinDb = absoluteMinDb ?? AudioMeter.defaultMinDb
    }
    
    init(buffer: AVAudioPCMBuffer) throws {
        guard let channelData = buffer.floatChannelData else {
            throw BufferReadingError.channelDataMissing
        }
        let channelDataValue = channelData.pointee
        //Convert pointer object to new array of samples
        let channelDataValueArray = stride(
            from: 0,
            to: Int(buffer.frameLength),
            by: buffer.stride
        ).map {
            channelDataValue[$0]
        }
        self.init(
            channelDataValueArray: channelDataValueArray,
            frameLength: buffer.frameLength
        )
        // Making a note to ask if channelData needs to be deallocated?
        // Crashes whereever I put it in this init.
//        channelData.deallocate()
    }
}
    
// MARK: COMPUTED VARS
extension BufferReading {
    private var rms: RootMeanSquare {
        return BufferReading.rms(
            fromChannelDataValueArray: channelDataValueArray,
            frameLength: frameLength
        )
    }
    
    var decibel: Decibel {
        return BufferReading.decibel(
            from: rms,
            absoluteMinDb: absoluteMinDb
        )
    }
}


// MARK: STATIC CALCULATIONS
extension BufferReading {
    /// Calculate the root mean square. squares all numbers, sums them, divides by total, and square roots that.
    private static func rms(
        fromChannelDataValueArray: [Float],
        frameLength: AVAudioFrameCount
    ) -> RootMeanSquare {
        let rms1 = fromChannelDataValueArray.map{ $0 * $0 }
        let rms2 = rms1.reduce(0, +)
        let rms3 = rms2 / Float(frameLength)
        let rms = sqrt(rms3)
        return rms
    }
    
    /// Calculate the decibel level
    /// - Parameters:
    ///   - fromRMS: the root mean square (quadratic mean) of an array of numbers.
    ///   - absoluteMinDb: the minimum decibel. If average power is quieter than this reading, absoluteMinDb will be returned.
    /// - Returns: The decibel calculation (average power).
    private static func decibel(
        from rms: RootMeanSquare,
        absoluteMinDb: Decibel
    ) -> Decibel{
        let avgPower = 20 * log10(rms)
        return (avgPower < absoluteMinDb) ? absoluteMinDb : avgPower
//        if avgPower < absoluteMinDb {
//            avgPower = absoluteMinDb
//        }
//        //SET MINIMUM DB for return. MAybe -80?
//        return avgPower
    }
}

// MARK: DEFINITIONS
extension BufferReading {
    
    enum BufferReadingError: ScorepioError {
        case channelDataMissing
        
        var message: String {
            switch self {
            case .channelDataMissing: return "Could not initialize buffer reading because channel data was not defined."
            }
        }
    }
}
