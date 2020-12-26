//
//  MeterMinimum.swift
//  Scorepio
//
//  Created by William Piotrowski on 1/27/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation

//Calculate 5 min high and low as opposed to complete high and low?
/// Calculates the lowest average decibel level.
class MeterMinimum {
    private var totalCapacity: ArrayLength = 20
    private var minimumDecibelReadings = [Decibel]()
    
    func append(decibelReading: Decibel){
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
    
    var highestDecibelReading: Decibel {
        return minimumDecibelReadings.last ?? 0
    }
    
    private var sum: Float {
        return minimumDecibelReadings.reduce(0, +)
    }
    
    private var arrayCount: ArrayLength {
        return minimumDecibelReadings.count
    }
    
    var average: Decibel {
        guard arrayCount > 0
            else { return 0 }
        return sum / Float(arrayCount)
    }
    
}
