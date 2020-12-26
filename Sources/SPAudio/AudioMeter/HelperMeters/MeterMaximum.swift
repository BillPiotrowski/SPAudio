//
//  MeterMaximum.swift
//  Scorepio
//
//  Created by William Piotrowski on 1/27/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation

//Calculate 5 min high and low as opposed to complete high and low?
/// Calculates the average maximum intensity level.
class MeterMaximum {
    private var totalCapacity: Int = 4
    private var maximumScaledLevelReadings = [AudioMeter.Intensity]()
    
    func append(intensity: AudioMeter.Intensity){
        if(maximumScaledLevelReadings.count < totalCapacity){
            maximumScaledLevelReadings.append(intensity)
        } else if (intensity > lowestScaledLevelReading) {
            maximumScaledLevelReadings.removeLast()
            maximumScaledLevelReadings.append(intensity)
        }
        maximumScaledLevelReadings.sort(by: >)
    }
    
    func reset(){
        maximumScaledLevelReadings.removeAll()
    }
    
    var lowestScaledLevelReading: AudioMeter.Intensity {
        return maximumScaledLevelReadings.last ?? 0
    }
    
    private var sum: Float {
        return maximumScaledLevelReadings.reduce(0, +)
    }
    
    private var arrayCount: ArrayLength {
        return maximumScaledLevelReadings.count
    }
    
    var average: AudioMeter.Intensity {
        guard arrayCount > 0
            else { return 0 }
        return sum / Float(arrayCount)
    }
}
