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

class DurationMeter {
    private let totalCapacity: Int = 100
    private var scaledReadings = [Float]()

    //var slowSpeedSeconds: Float = 7
    var fastSpeedSeconds: Float = 2.5
    
    private var timeMultipler: Float = 1
    
    func append(scaledReading: Float){
        scaledReadings.insert(scaledReading, at: 0)
        let extraReadingsCount = scaledReadings.count - totalCapacity
        if extraReadingsCount > 0 {
            scaledReadings.removeLast(extraReadingsCount)
        }
    }
    func reset(){
        scaledReadings.removeAll()
    }
    func setTime(multiplier: Float){
        timeMultipler = multiplier
    }
    private var fastArrayCount: Int {
        return DurationMeter.arrayCount(
            withSeconds: fastSpeedSeconds,
            timeMultipler: timeMultipler,
            maximumCapacity: scaledReadings.count
        )
    }
    /*
    private var slowArrayCount: Int {
        return DurationMeter.arrayCount(
            withSeconds: slowSpeedSeconds,
            timeMultipler: timeMultipler,
            maximumCapacity: scaledReadings.count
        )
    }
    */
    private static func arrayCount(
        withSeconds: Float,
        timeMultipler: Float,
        maximumCapacity: Int
    ) -> Int {
        let fastArrayCount = Int(withSeconds * timeMultipler)
        switch fastArrayCount {
        case _ where fastArrayCount < 1: return 1
        case _ where fastArrayCount > maximumCapacity: return maximumCapacity
        default: return fastArrayCount
        }
    }
    
    private var fastArray: [Float] {
        return Array(scaledReadings[0..<fastArrayCount])
    }
    /*
    private var slowArray: [Float] {
        return Array(scaledReadings[0..<slowArrayCount])
    }
 */
    var fastReading: Float {
        let meterReading = SingleMeterReading(meterArray: fastArray)
        return meterReading.level
    }
    /*
    var slowReading: Float {
        let meterReading = SingleMeterReading(meterArray: slowArray)
        return meterReading.level
    }
     */
    
}
