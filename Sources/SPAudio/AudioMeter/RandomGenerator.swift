//
//  RandomGenerator.swift
//  Scorepio
//
//  Created by William Piotrowski on 2/5/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation

public class RandomGenerator {
    private var location: Float {
        didSet {
            guard let callback = callback else {
                return
            }
            callback(location)
        }
    }
    /// Duration in seconds of time it takes to move to next random location.
    private var movementDuration: Double
    private let audioEngine: AudioEngineProtocol
    private var movement: Movement
    var callback: ((Float) -> Void)?
    
    /// Default duration in seconds of time it takes to move to next random location.
    static let defaultDuration: Double = 5
    public private (set) var isRunning: Bool = false
    
    public init(
        audioEngine: AudioEngineProtocol,
        callback: ((Float) -> Void)? = nil,
        startingAt: Float? = nil,
        duration: Double? = nil
    ){
        self.audioEngine = audioEngine
        self.callback = callback
        self.movementDuration = duration ?? RandomGenerator.defaultDuration
        let startingAt = startingAt ?? 0
        self.location = startingAt
        self.movement = Movement(
            startValue: startingAt
        )
    }
    
    
    
    
}
extension RandomGenerator: AudioEngineObserver {
    public func audioEngineUpdated() {
        self.location = movement.currentValue
        if (movement.complete) {
            newMovement()
        }
    }
}

extension RandomGenerator {
    private func newMovement(){
        self.movement = Movement(
            startValue: location
        )
    }
    
    public func start(){
        audioEngine.addObserver2(self)
        isRunning = true
    }
    
    public func stop(){
        audioEngine.removeObserver2(self)
        isRunning = false
    }
    
    
    /// Generates a random Float value between 0 and 1
    static var randomFloat: Float {
        return Float.random(in: 0...1)
    }

    struct Movement {
        let startTime: Date
        let startValue: Float
        let duration: Double
        let destination: Float
        
        public init(
            startValue: Float,
            duration: Double? = nil,
            startTime: Date? = nil,
            destination: Float? = nil
        ){
            self.startTime = startTime ?? Date()
            self.startValue = startValue
            self.duration = duration ?? RandomGenerator.defaultDuration
            self.destination = destination ?? RandomGenerator.randomFloat
        }
    }
}
