//
//  RandomGeneratorMovement.swift
//  Scorepio
//
//  Created by William Piotrowski on 2/5/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation

// MARK: INTERVAL SINCE START
extension RandomGenerator.Movement {
    var intervalSinceStart: Double {
        return self.intervalSinceStart()
    }
    func intervalSinceStart(currentTime: Date? = nil) -> Double {
        let currentTime = currentTime ?? Date()
        return RandomGenerator.Movement.intervalSinceStart(
            startTime: self.startTime,
            currentTime: currentTime
        )
    }
    static func intervalSinceStart(
        startTime: Date,
        currentTime: Date
    ) -> Double {
        return currentTime.timeIntervalSince(startTime)
    }
}

// MARK: PCT COMPLETE
extension RandomGenerator.Movement {
    var percentComplete: Double {
        return self.percentComplete()
    }
    func percentComplete(currentTime: Date? = nil) -> Double {
        let interval = intervalSinceStart(
            currentTime: currentTime
        )
        return RandomGenerator.Movement.percentComplete(
            intervalSinceStart: interval,
            duration: self.duration
        )
    }
    static func percentComplete(
        intervalSinceStart: Double,
        duration: Double
    ) -> Double {
        return intervalSinceStart / duration
    }
    
}

// MARK: OTHER CALCULATIONS
extension RandomGenerator.Movement {
    /// Float defining the total distance between the starting value and destination. Can be positive or negative.
    var totalMovement: Float {
        return destination - startValue
    }
    /// The distance between the starting value and it's location at an exact moment in time.
    var currentOffset: Float {
        let offset = totalMovement * Float(percentComplete)
        guard abs(offset) < abs(totalMovement)
            else { return totalMovement }
        return offset
    }
    /// A Float describing the currentOffset plus the original starting value.
    var currentValue: Float {
        return startValue + currentOffset
    }
    /// A boolean describing if the movement has reached its final destination.
    var complete: Bool {
        return (percentComplete >= 1) ? true : false
    }
}
