//
//  File.swift
//  
//
//  Created by William Piotrowski on 12/26/20.
//

import SPCommon

// MARK: DECIBEL
/**
 Reading of audio level. 0 is loudest.
 
 May want to double check calculations that happen internally against mathematics texts.
 */
internal typealias Decibel = Float


// MARK: RMS
/**
The root mean square. (quadratic mean)
 
Calculated by:
 
Squaring all numbers in an array;

Averaging those squares; and,

Returning the square root.
*/
internal typealias RootMeanSquare = Float


/// The number of elements in an array. An integer.
internal typealias ArrayLength = Int



// MARK: SCOREPIO METER DEFINITIONS
extension AudioMeter {
    /// Decibel Ratio (a number between 0 and 1 used to represent actual decibel measurement) adjusted by intensity multiplier to ensure dynamic range.
    public typealias Intensity = Float
    
    /// A multiplier to scale up or down a decibel ratio to alter dynamic range.
    internal typealias IntensityMultipler = Float
    
    /// A ratio of a decibel reading between 0 and 1. Absolute minimum Decibel level must be provided to calculate
    typealias DecibelRatio = Float
    
    /// Duration in seconds.
    typealias Second = Float
    
}

// MARK: DEFINITIONS
extension AudioMeter {
    
    enum AudioMeterError: ScorepioError {
        case couldNotStartAlreadyRunning
        case couldNotStartNoNode
        
        var message: String {
            switch self {
            case .couldNotStartNoNode: return "Could not start audio meter because there is not a node defined."
            case .couldNotStartAlreadyRunning: return "Could not start audio meter because it is already running."
            }
        }
    }
    
    public enum AudioMeterProperty {
        case fastSpeed(ratio: Float)
        //case slowSpeed(ratio: Float)
    }
    
    enum State {
        case running
        case off
    }
}
