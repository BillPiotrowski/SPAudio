//
//  AudioEffects.swift
//  WPAudio
//
//  Created by William Piotrowski on 7/1/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import AVFoundation

// MOVE DEFAULTS TO READ FROM MEDIA DATA!!!!

//Need to impliment inheretence from parent track. Figure out how to gracefully save and handle in UI
public class AudioEffects{
    private let reverb = AVAudioUnitReverb()
    private let delay = AVAudioUnitDelay()
    private let effectsMix = AVAudioMixerNode()
    private let delayMix = AVAudioMixerNode()
    private let effectsIn = AVAudioMixerNode()
    private let outputConnectionPoints: [AVAudioConnectionPoint]
    private let defaultAudioFormat: AVAudioFormat?
    private let audioEngine: AudioEngine
    public private(set) var isConnected: Bool = false
    
    public init(
        audioEngine: AudioEngine,
        outputConnectionPoints: [AVAudioConnectionPoint],
        defaultAudioFormat: AVAudioFormat?
    ){
        self.audioEngine = audioEngine
        self.outputConnectionPoints = outputConnectionPoints
        self.defaultAudioFormat = defaultAudioFormat
        attach()
        delay.wetDryMix = 100
    }
    
    private func attach(){
        engine.attach(delay)
        engine.attach(reverb)
        engine.attach(effectsMix)
        engine.attach(effectsIn)
        engine.attach(delayMix)
    }
}

// MARK: PUBLIC FUNCTIONS
extension AudioEffects {
    public func set(properties: [AudioEffects.Property]){
        for property in properties {
            set(property: property)
        }
    }
    public func set(property: AudioEffects.Property){
        switch property {
        case .delayFeedback(let feedback): delay.feedback = feedback * 200 - 100
        case .delayMix(let value): delayMix.volume = value
        case .delayTime(let seconds):
            var filteredSeconds = seconds
            if filteredSeconds > 2 {
                filteredSeconds = 2
                print("WARNING: FX Delay time can not be larger than 2 seconds. Set to 2 seconds.")
            }
            delay.delayTime = Double(filteredSeconds)
        case .masterFX(let mix): effectsMix.volume = mix
        case .reverb(let mix): reverb.wetDryMix = mix * 100
        }
    }
    
    public func connect() throws {
        let outPoints = try AVAudioConnectionPoint.connectable(outputConnectionPoints)
        engine.connect(effectsIn, to: delay, format: defaultAudioFormat)
        engine.connect(delay, to: delayMix, format: defaultAudioFormat)
        engine.connect(delayMix, to: reverb, format: defaultAudioFormat)
        engine.connect(reverb, to: effectsMix, format: defaultAudioFormat)
        engine.connect(effectsMix, to: outPoints, fromBus: 0, format: defaultAudioFormat)
        self.isConnected = checkConnection()
    }
    public func disconnect(){
        engine.disconnectNodeOutput(effectsIn)
        engine.disconnectNodeOutput(delay)
        engine.disconnectNodeOutput(delayMix)
        engine.disconnectNodeOutput(reverb)
        engine.disconnectNodeOutput(effectsMix)
        self.isConnected = checkConnection()
    }
    func checkConnection() -> Bool{
        guard
            effectsIn.isOutputConnected,
            delay.isOutputConnected,
            delayMix.isOutputConnected,
            reverb.isOutputConnected,
            effectsMix.isOutputConnected
        else { return false }
        return true
    }
    public func getInputConnectionPoint(bus: Int) -> AVAudioConnectionPoint {
        return AVAudioConnectionPoint(node: effectsIn, bus: bus)
    }
}

// READ DEFAULTS FROM MEDIA DATA!!!!
extension AudioEffects {
    private var defaults: [AudioEffects.Property] {
        return [
            /*
            .delayFeedback(
                feedback: TrackEffectsData.defaultDelayFeedback
            ),
            .delayTime(seconds: TrackEffectsData.defaultDelayTime),
            .delayMix(value: TrackEffectsData.defaultReverbMix),
            .masterFX(mix: TrackEffectsData.defaultMasterFX),
            .reverb(mix: TrackEffectsData.defaultReverbMix)
 */
            .delayFeedback(feedback: AudioEffects.defaultDelayFeedback),
            .delayTime(seconds: AudioEffects.defaultDelayTime),
            .delayMix(value: AudioEffects.defaultReverbMix),
            .masterFX(mix: AudioEffects.defaultMasterFX),
            .reverb(mix: AudioEffects.defaultReverbMix)
        ]
    }
    
    // PREVIOUSLY HAD DEFAULTS SET IN MediaData, but prefer to decouple
    // Good to double check that they are the same. Maybe a unit test as a reminder?
    public static let defaultDelayFeedback: Float = 0.6
    public static let defaultDelayTime: Double = 0.5
    public static let defaultDelayMix: Float = 1
    public static let defaultMasterFX: Float = 0.6
    public static let defaultReverbMix: Float = 0.6
 
    
    var engine: AVAudioEngine {
        return audioEngine.engine
    }
}


// MARK: DEFINITIONS
extension AudioEffects {
    public enum Property {
        case reverb(mix: Float)
        /// Delay time is measured in seconds and can be from 0 to 2.
        case delayTime(seconds: Double)
        case delayFeedback(feedback: Float)
        case delayMix(value: Float)
        case masterFX(mix: Float)
    }
}
