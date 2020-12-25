//
//  TrailingMeter.swift
//  Scorepio
//
//  Created by William Piotrowski on 2/7/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation


public class TrailingMeter {
    
    private var values = [TimeValue]()
    
    /// Duration in seconds of time it takes to move to next random location.
    public private (set) var duration: Double
    //private let audioEngine: AudioEngine
    
    /// Default duration in seconds of time it takes to move to next random location.
    static let defaultDuration: Double = 7
    private (set) var isRunning: Bool = false
    
    public init(
        duration: Double? = nil
    ){
        self.duration = duration ?? TrailingMeter.defaultDuration
    }
    
    /// Remove the array values that are older than the trailing duration.
    private func purgeOld(){
        let currentTime = Date()
        values.removeAll(where: {
            currentTime.timeIntervalSince($0.time) > duration
        })
    }
    private var sum: Float {
        return values.reduce(into: 0, { (result, timeValue) in
            result += timeValue.value
            
        })
    }
    
    private var arrayCount: Float {
        return Float(values.count)
    }
    
    // HANDLE ON BACKGROUND THREAD TO AVOID RACE CONDITION?
    /// Calculates the average over the trailing duration.
    public var average: Float {
        purgeOld()
        guard arrayCount > 0
            else { return 0 }
        return sum / arrayCount
    }
    
}

extension TrailingMeter {
    
    public func append(value: Float){
        values.append(
            TimeValue(time: Date(), value: value)
        )
    }
    
    struct TimeValue {
        let time: Date
        let value: Float
    }
    
    public func set(property: Property){
        switch property {
        case .duration(let seconds): self.duration = seconds
        }
    }
    
    public func set(properties: [Property]){
        for property in properties {
            self.set(property: property)
        }
    }

}

extension TrailingMeter {
    public enum Property {
        case duration(seconds: Double)
    }
}
