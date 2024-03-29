//
//  DurationMeter.swift
//  Scorepio
//
//  Created by William Piotrowski on 1/27/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation

// ABSTRACT THIS FROM THE ARBITRARY TIMING OF THE AUDIO METER??
// Have audio meter send data that is stored in a new 'buffer' array.
// Then create a timer that empties and analyzes the buffer.

/// Caclulates the average decibelRatio over the last x amount of seconds.
class TimedMeter {
    /// The maximum capacity of the array. Anything added beyond this number, regardless of the speed will be removed.
    private static let totalCapacity: ArrayLength = 100
    
    /// The array of decibel ratios.
    private var scaledReadings = [AudioMeter.DecibelRatio]()
    
    /// The duration that is used to determine the average. i.e. a 2.5 speed will average all of the readings over the most recent 2.5 seconds.
    var speed: Second
    static let defaultSpeed: Second = 2.5
    
    /// The duration of each single reading
    private var singleReadingDuration: Second = 0.1
    
    init(
        speed: Second? = nil
    ){
        self.speed = TimedMeter.defaultSpeed
    }
    
}

// MARK: INTERNAL METHODS AND PROPERTIES
extension TimedMeter {
    /// The average decibel ratio over the speed of meter.
    internal var average: AudioMeter.DecibelRatio {
        let meterReading = MeterReadingArray(
            meterArray: arraySubsetBasedOnSpeed
        )
        return meterReading.average
    }
    
    /// Add a new meter reading.
    internal func append(decibelRatio: AudioMeter.DecibelRatio){
        scaledReadings.insert(decibelRatio, at: 0)
        let extraReadingsCount = scaledReadings.count - TimedMeter.totalCapacity
        if extraReadingsCount > 0 {
            scaledReadings.removeLast(extraReadingsCount)
        }
    }
    
    /// Reset the meter making it empty.
    internal func reset(){
        scaledReadings.removeAll()
    }
    
    /// Sets the length of a single reading. This is used to calculate how many readings will be averaged based on the speed of the meter.
    internal func set(
        singleReadingDuration: Second
    ){
        self.singleReadingDuration = singleReadingDuration
    }
    
}

// MARK: HELPER VAR
extension TimedMeter {
    /// Subset of the scaledReadings array based on the set speed.
    private var arraySubsetBasedOnSpeed: [AudioMeter.DecibelRatio] {
        return Array(scaledReadings[0..<arrayLengthFromSpeed])
    }
}

// MARK: INTERNAL CALCULATIONS
extension TimedMeter {
    /// Calculates the length of the array based on the speed that is set.
    private var arrayLengthFromSpeed: ArrayLength {
        return TimedMeter.arrayLengthFromSpeed(
            meterSpeed: speed,
            readingDuration: singleReadingDuration,
            maximumCapacity: scaledReadings.count
        )
    }
    
    /// Calculates the length of the array based on the speed that is set.
    private static func arrayLengthFromSpeed(
        meterSpeed: Second,
        readingDuration: Second,
        maximumCapacity: ArrayLength
    ) -> ArrayLength {
        let fastArrayCount = Int(meterSpeed * readingDuration)
        switch fastArrayCount {
        case _ where fastArrayCount < 1: return 1
        case _ where fastArrayCount > maximumCapacity: return maximumCapacity
        default: return fastArrayCount
        }
    }
}


