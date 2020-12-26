//
//  File.swift
//  
//
//  Created by William Piotrowski on 12/26/20.
//

import Foundation

public struct MeterReading {
    public let intensityFast: Float
    public let intensitySlow: Float
    public let triggerWords: [String]
    
    internal init(
        intensityFast: Float,
        intensitySlow: Float,
        triggerWords: [String] = []
    ){
        self.intensityFast = intensityFast
        self.intensitySlow = intensitySlow
        self.triggerWords = triggerWords
    }
}
