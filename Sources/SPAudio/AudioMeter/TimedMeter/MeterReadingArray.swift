//
//  SingleMeterReading.swift
//  Scorepio
//
//  Created by William Piotrowski on 1/27/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation

/// An enclusure that calculates the average
internal struct MeterReadingArray {
    private let meterArray: [Float]
    
    init(meterArray: [Float]){
        self.meterArray = meterArray
    }
    
    /// Adds all of the array elements of meter array.
    private var sum: Float {
        return meterArray.reduce(0, +)
    }
    
    /// A float describing the count of elements in meter array.
    private var arrayCount: Float {
        return Float(meterArray.count)
    }
    
    /// The average of all of the readings in meter array.
    var average: Float {
        guard arrayCount > 0
            else { return 0 }
        return sum / arrayCount
    }
}
