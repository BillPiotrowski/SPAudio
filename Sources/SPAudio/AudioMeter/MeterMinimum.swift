//
//  MeterMinimum.swift
//  Scorepio
//
//  Created by William Piotrowski on 1/27/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation

//Calculate 5 min high and low as opposed to complete high and low?
class MeterMinimum {
    private var totalCapacity: Int = 20
    private var minimumDecibelReadings = [Float]()
    
    func append(decibelReading: Float){
        if(minimumDecibelReadings.count < totalCapacity){
            minimumDecibelReadings.append(decibelReading)
        } else if (decibelReading < highestDecibelReading) {
            minimumDecibelReadings.removeLast()
            minimumDecibelReadings.append(decibelReading)
        }
        minimumDecibelReadings.sort()
    }
    
    func reset(){
        minimumDecibelReadings.removeAll()
    }
    
    var highestDecibelReading: Float {
        return minimumDecibelReadings.last ?? 0
    }
    
    private var sum: Float {
        return minimumDecibelReadings.reduce(0, +)
    }
    
    private var arrayCount: Float {
        return Float(minimumDecibelReadings.count)
    }
    
    var average: Float {
        guard arrayCount > 0
            else { return 0 }
        return sum / arrayCount
    }
    
}
