//
//  MeterMaximum.swift
//  Scorepio
//
//  Created by William Piotrowski on 1/27/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation

//Calculate 5 min high and low as opposed to complete high and low?
class MeterMaximum {
    private var totalCapacity: Int = 4
    private var maximumScaledLevelReadings = [Float]()
    
    func append(scaledLevel: Float){
        if(maximumScaledLevelReadings.count < totalCapacity){
            maximumScaledLevelReadings.append(scaledLevel)
        } else if (scaledLevel > lowestScaledLevelReading) {
            maximumScaledLevelReadings.removeLast()
            maximumScaledLevelReadings.append(scaledLevel)
        }
        maximumScaledLevelReadings.sort(by: >)
    }
    
    func reset(){
        maximumScaledLevelReadings.removeAll()
    }
    
    var lowestScaledLevelReading: Float {
        return maximumScaledLevelReadings.last ?? 0
    }
    
    private var sum: Float {
        return maximumScaledLevelReadings.reduce(0, +)
    }
    
    private var arrayCount: Float {
        return Float(maximumScaledLevelReadings.count)
    }
    
    var average: Float {
        guard arrayCount > 0
            else { return 0 }
        return sum / arrayCount
    }
}
