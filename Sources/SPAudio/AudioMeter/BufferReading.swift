//
//  BufferReading.swift
//  Scorepio
//
//  Created by William Piotrowski on 1/22/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import AVFoundation

struct BufferReading {
    private var absoluteMinDb: Float
    let channelDataValueArray: [Float]
    let frameLength: AVAudioFrameCount
    
    init(
        channelDataValueArray: [Float],
        frameLength: AVAudioFrameCount,
        absoluteMinDb: Float? = nil
    ){
        self.channelDataValueArray = channelDataValueArray
        self.frameLength = frameLength
        self.absoluteMinDb = absoluteMinDb ?? -60.0
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
    }
    
    enum BufferReadingError: ScorepioError {
        case channelDataMissing
        
        var message: String {
            switch self {
            case .channelDataMissing: return "Could not initialize buffer reading because channel data was not defined."
            }
        }
    }
    
    var rms: Float {
        return BufferReading.rms(fromChannelDataValueArray: channelDataValueArray, frameLength: frameLength)
    }
    
    var decibel: Float {
        return BufferReading.decibel(fromRMS: rms, absoluteMinDb: absoluteMinDb)
    }
    
    /// Calculate the root mean square. squares all numbers, sums them, divides by total, and square roots that.
    private static func rms(
        fromChannelDataValueArray: [Float],
        frameLength: AVAudioFrameCount
    ) -> Float{
        let rms1 = fromChannelDataValueArray.map{ $0 * $0 }
        let rms2 = rms1.reduce(0, +)
        let rms3 = rms2 / Float(frameLength)
        let rms = sqrt(rms3)
        return rms
    }
    
    /// Calculate the decibel level
    private static func decibel(
        fromRMS: Float,
        absoluteMinDb: Float
    ) -> Float{
        var avgPower = 20 * log10(fromRMS)
        if avgPower < absoluteMinDb {
            avgPower = absoluteMinDb
        }
        //SET MINIMUM DB for return. MAybe -80?
        return avgPower
    }
    
}
