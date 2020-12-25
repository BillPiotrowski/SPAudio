//
//  MeterTimeRatio.swift
//  Scorepio
//
//  Created by William Piotrowski on 1/27/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation

public struct MeterTimeRatio {
    let floor: Float
    let multiplier: Float
    
    public init(
        floor: Float,
        multiplier: Float
    ){
        self.floor = floor
        self.multiplier = multiplier
    }
    
    /// Calculates the amount of seconds from a ratio (0-1), floor offset, and multiplier
    public func seconds(fromRatio: Float) -> Float {
        return MeterTimeRatio.seconds(
            ratio: fromRatio,
            floor: floor,
            multiplier: multiplier
        )
    }
    
    public func ratio(fromSeconds: Float) -> Float {
        return MeterTimeRatio.ratio(
            seconds: fromSeconds,
            floor: floor,
            multiplier: multiplier
        )
    }
    
    /// Calculates the amount of seconds from a ratio (0-1), floor offset, and multiplier
    static func seconds(
        ratio: Float,
        floor: Float,
        multiplier: Float
    ) -> Float {
        return floor + (ratio * multiplier)
    }
    
    static func ratio(
        seconds: Float,
        floor: Float,
        multiplier: Float
    ) -> Float {
        return (seconds - floor) / multiplier
    }
}
