//
//  File.swift
//  
//
//  Created by William Piotrowski on 12/27/20.
//

import Foundation
import AVFoundation
import SPCommon

extension AudioEngine {
    /// Creates a noise signal in the form of an array of Doubles. Primarily used for unit testing.
    internal static func createNoise(length: Int) -> [Double] {
        var array = [Double]()
        for _ in 0..<length {
            array.append(Double.random(in: -1...1))
        }
        return array
    }
    /// Creates a signal from repeating a pattern. Primarily used for unit testing.
    internal static func createBuffer(from pattern: [Double], length: Int) -> [Double]{
        var array = pattern
        while (array.count + pattern.count) < length {
            array.append(contentsOf: pattern)
        }
        return array
    }
    
    internal static func createTestSignalBuffer(
        length: Int,
        sampleRate: Double,
        settings: [String: Any]
    ) throws -> AVAudioPCMBuffer {
        let pattern: [Double] = [1,1,0.25,-0.25,-1,-0.5,0,0.5]
        let buff = AudioEngine.createBuffer(
            from: pattern,
            length: length
        )

        guard
            let bufferFormat = AVAudioFormat(settings: settings)
        else { throw AudioGeneratorError.badFormat }
        
        guard
            let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: bufferFormat,
                frameCapacity: AVAudioFrameCount(buff.count)
            )
        else { throw AudioGeneratorError.badBuffer }

        // i had my samples in doubles, so convert then write

        for i in 0..<buff.count {
            outputBuffer.floatChannelData!.pointee[i] = Float( buff[i] )
        }
        
        outputBuffer.frameLength = AVAudioFrameCount( buff.count )
        return outputBuffer
    }
    
    internal static func createAudioFileTestSignal(
        at url: URL,
        sampleRate: Double,
        length: Int
    ) throws -> AVAudioFile{
        
        let sampleRateFloat64 = Float64(sampleRate)

        let outputFormatSettings = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            //  AVLinearPCMIsBigEndianKey: false,
            AVSampleRateKey: sampleRateFloat64,
            AVNumberOfChannelsKey: 1
        ] as [String : Any]
        
        let buffer = try AudioEngine.createTestSignalBuffer(
            length: length,
            sampleRate: sampleRate,
            settings: outputFormatSettings
        )
        
        let audioFile = try AVAudioFile(
            forWriting: url,
            settings: outputFormatSettings,
            commonFormat: AVAudioCommonFormat.pcmFormatFloat32,
            interleaved: true
        )
        try audioFile.write(from: buffer)
        return audioFile
        
    }
}


private enum AudioGeneratorError: ScorepioError {
    case badFormat
    case badBuffer
    
    var message: String {
        switch self {
        case .badFormat: return "Could not create buffer format from settings."
        case .badBuffer: return "Could not create buffer from buffer format and frame capacity."
        }
    }
}
