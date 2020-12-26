//
//  ManualMeter.swift
//  Scorepio
//
//  Created by William Piotrowski on 2/12/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//
/*
import Foundation


public class ManualMeter {
    private let audioEngine: AudioEngineProtocol
    var trailingMeter: TrailingMeter
    var callback: ((Float) -> Void)?
    private (set) var value: Float
    
    public init(
        audioEngine: AudioEngineProtocol,
        trailingMeter: TrailingMeter,
        callback: ((Float) -> Void)? = nil,
        value: Float? = nil
    ){
        self.audioEngine = audioEngine
        self.trailingMeter = trailingMeter
        self.callback = callback
        self.value = value ?? ManualMeter.defaultValue
    }
    
    public func start(){
        audioEngine.addObserver2(self)
    }
    
    public func stop(){
        audioEngine.removeObserver2(self)
    }
    
    public func set(value: Float){
        self.value = AudioMeter.filter(number: value)
        guard let callback = callback
            else { return }
        callback(self.value)
    }
    
}

extension ManualMeter: AudioEngineObserver {
    public func audioEngineUpdated() {
        trailingMeter.append(value: self.value)
        guard let callback = callback
            else { return }
        callback(self.value)
    }
    
}

// MARK: DEFAULTS
extension ManualMeter {
    static let defaultValue: Float = 0
}
*/
