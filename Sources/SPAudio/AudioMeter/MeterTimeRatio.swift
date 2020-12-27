//
//  MeterTimeRatio.swift
//  Scorepio
//
//  Created by William Piotrowski on 1/27/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation

// Also Used in Input Brain's TrailingMeter

// TO-DO:   Create round trip unit test.
//          Tighten up calculation with minumum?

public struct MeterTimeRatio {
    let minimumDuration: Second
    let multiplier: Second
    
    /// Calculates the duration in seconds from a ratio
    /// - Parameters:
    ///   - minimumDuration: the minimum duration. All durations will be at least this long, and the ratio will be calculated in addition to the minimum
    ///   - multiplier: The maximum duration in addition to the minimum. Final duration is calculated by multiplying this by the ratio (0 to 1) and then adding the minimum.
    public init(
        minimumDuration: Second,
        multiplier: Second
    ){
        self.minimumDuration = minimumDuration
        self.multiplier = multiplier
    }
    
    /// Initializes by defining min and max.
    /// - Parameters:
    ///   - minimumDuration: The slowest duration possible in seconds.
    ///   - maximumDuration: The fastest duration possible in seconds.
    public init(
        minimumDuration: Second,
        maximumDuration: Second
    ){
        let multiplier = MeterTimeRatio.multiplier(
            minimumDuration: minimumDuration,
            maximumDuration: maximumDuration
        )
        self.init(
            minimumDuration: minimumDuration,
            multiplier: multiplier
        )
    }
}


extension MeterTimeRatio {
    /// Calculates the amount of seconds from a ratio (0-1), floor offset, and multiplier
    public func seconds(from ratio: Ratio) -> Second {
        return MeterTimeRatio.seconds(
            ratio: ratio,
            floor: minimumDuration,
            multiplier: multiplier
        )
    }
    
    public func ratio(from seconds: Second) -> Ratio {
        return MeterTimeRatio.ratio(
            seconds: seconds,
            floor: minimumDuration,
            multiplier: multiplier
        )
    }
    
    public var maximumDuration: Second {
        return MeterTimeRatio.maximumDuration(
            multiplier: self.multiplier,
            minimumDuration: self.minimumDuration
        )
    }
}

// MARK: CALCULATIONS
extension MeterTimeRatio {
    /// Calculates the amount of seconds from a ratio (0-1), floor offset, and multiplier
    private static func seconds(
        ratio: Ratio,
        floor: Second,
        multiplier: Second
    ) -> Second {
        return floor + (ratio * multiplier)
    }
    
    private static func ratio(
        seconds: Second,
        floor: Second,
        multiplier: Second
    ) -> Ratio {
        return (seconds - floor) / multiplier
    }
    
    private static func multiplier(
        minimumDuration: Second,
        maximumDuration: Second
    ) -> Second {
        return maximumDuration - minimumDuration
    }
    
    private static func maximumDuration(
        multiplier: Second,
        minimumDuration: Second
    ) -> Second {
        return multiplier + minimumDuration
    }
}

// MARK: DEFINITIONS
extension MeterTimeRatio {
    /// A number from 0 to 1 used to calculate the duration in seconds.
    public typealias Ratio = Float
    
    /// A Float number used to scale the ratio. Is calculated by subtracting the floor from the maximum.
    //public typealias Multiplier = Float
}
