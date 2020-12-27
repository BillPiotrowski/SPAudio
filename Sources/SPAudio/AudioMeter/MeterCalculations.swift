//
//  File.swift
//  
//
//  Created by William Piotrowski on 12/26/20.
//

import Foundation

// MARK: CALCULATIONS
extension AudioMeter {
    /// Calculates the scale to multiply raw level ratios by to increase dynamic range. Returns a number that can be used to multiply the Decibel ratio by to get a more full range of dynamics.
    static func scale(
        maximumRatio: Intensity,
        limit: Float? = 10
    ) -> IntensityMultipler {
        let limit = limit ?? 10
        let scale = 1 / maximumRatio
        return (scale > limit) ? limit : scale
    }
}

// MARK: CALC: dB Ratio
extension AudioMeter {
    
    /// convert decibel readings to a ratio of 0 to 1
    internal func decibelRatio(
        from decibel: Decibel
    ) -> DecibelRatio {
        return AudioMeter.decibelRatio(
            from: decibel,
            minimumDB: averageMinimumDecibel
        )
    }
    
    /// convert decibel readings to a ratio of 0 to 1
    static func decibelRatio (
        from decibel: Decibel,
        minimumDB: Decibel
    ) -> DecibelRatio {
        //Convert decibel to scale of 1
        guard decibel.isFinite
            else { return 0.0 }
        //Possibly set alt min in case there is no average
        
        // Calculate before switch and use that value to determine?
        switch decibel {
        case _ where decibel < minimumDB: return 0
        case _ where decibel >= 1.0: return 1.0
        default: return (abs(minimumDB) - abs(decibel)) / abs(minimumDB)
        }
    }
}


// MARK: CALC: FILTER RANGE
extension AudioMeter {
    /// Ensures that the number is less than or equal to 1 and greater than or equal to 0.
    public static func filter(
        number: Float,
        max: Float? = nil,
        min: Float? = nil
    ) -> Float {
        let max = max ?? 1
        let min = min ?? 0
        
        switch number {
        case _ where number < min: return min
        case _ where number > max: return max
        default: return number
        }
    }
}
