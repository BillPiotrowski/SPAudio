//
//  File.swift
//  
//
//  Created by William Piotrowski on 12/27/20.
//

import Foundation

// MARK: STATE DEFINITION
extension AudioSequencer {
    public enum State: Equatable {
        case empty
        case cued
    }
}

// MARK: SETTABLE PROPERTIES
extension AudioSequencer {
    public enum SettableProperty {
        case FXSend(volume: Volume)
        case outputVolume(volume: Volume)
    }
    
    public struct Settings: Equatable {
        let fxSend: Volume
        let volume: Volume
        
        var properties: [SettableProperty] {
            return [
                .FXSend(volume: fxSend),
                .outputVolume(volume: volume)
            ]
        }
    }
}

// MARK: DEFAULTS
extension AudioSequencer {
    public static var defaultSettings: Settings {
        return Settings(fxSend: 1, volume: 1)
    }
}
