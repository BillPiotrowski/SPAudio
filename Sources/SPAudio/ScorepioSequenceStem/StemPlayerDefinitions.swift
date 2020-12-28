//
//  File.swift
//  
//
//  Created by William Piotrowski on 12/27/20.
//

import Foundation

// MARK: DEFINITIONS
extension StemPlayer {
    internal enum AudioTrackState {
        case empty
        case cued
    }
}

// MARK: SETTABLE PROPERTY
extension StemPlayer {
    /// Actionable properties. Each of these settings will make an actionable change to the player when sent to the set(:) function
    public enum SettableProperty {
        case FXSend(postFaderRatio: Volume)
        /// Uses a number between 0 and 1.0 with 0.5 being centered.
        case panControl(value: PanControl)
        case volume(value: Volume)
        case pitchModulation(rate: PitchRate)
        case loop(value: Bool)
        case mute(muted: Bool)
        /// Uses a number between -1.0 and 1, with 0 being the center.
        case pan(pan: Pan)
    }
}

// MARK: SETTINGS STRUCT
extension StemPlayer {
    /// A comprehensive definition of a Stem Player's settings. More defined than an array of settable properties.
    public struct Settings: Equatable {
        let volume: Volume
        let pan: Pan
        let isMuted: Bool
        let fxSend: Volume
        let loop: Bool
        let pitchRate: PitchRate
        
        public var properties: [StemPlayer.SettableProperty] {
            return [
                .volume(value: volume),
                //.panControl(value: panControl),
                .pan(pan: pan),
                .mute(muted: isMuted),
                .FXSend(postFaderRatio: fxSend),
                .loop(value: loop),
                .pitchModulation(rate: pitchRate)
            ]
        }
        
        public var panControl: PanControl {
            return Settings.panControl(from: self.pan)
        }
        
        /// Can cause rounding errors if looking for exact match
        public static func pan(from panControl: PanControl) -> Pan {
            return ((panControl * 2) - 1)
        }
        /// Can cause rounding errors if looking for exact match
        public static func panControl(from pan: Pan) -> PanControl {
            return (pan + 1) / 2
        }
    }
}

// MARK: DEFAULT SETTINGS
extension StemPlayer {
    public static var defaultSettings: Settings {
        return Settings(
            volume: 0.8,
            pan: 0,
            isMuted: false,
            fxSend: 0.1,
            loop: false,
            pitchRate: 1
        )
    }
}


/// The default value is 1.0. The range of valid values is 0.0 to 1.0
public typealias Volume = Float
/// The default value is 0.0. A value in the range -1.0 to 1.0.
public typealias Pan = Float
/// The default value is 0.5. A value in the range 0 to 1.0.
public typealias PanControl = Float
/// The varispeed audio unit resamples the input signal, as a result changing the playback rate also changes the pitch. For example, changing the rate to 2.0 results in the output audio playing one octave higher. Similarly changing the rate to 0.5, results in the output audio playing one octave lower.
public typealias PitchRate = Float

