//
//  AudioTrack.swift
//  WPAudio
//
//  Created by William Piotrowski on 7/2/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import AVFoundation
import AVKit
import ReactiveSwift
import SPCommon



public class StemPlayer {
    internal let inputMixer = AVAudioMixerNode()
    internal let outputMixer = AVAudioMixerNode()
    internal let pitchAU = AVAudioUnitVarispeed()
    internal let fxMixer = AVAudioMixerNode()
    internal let audioPlayer: AudioPlayer
    private let fxConnectionPoints: [AVAudioConnectionPoint]
    private let outputConnectionPoints: [AVAudioConnectionPoint]
    private let audioEngine: AudioEngineProtocol

    
    
    // Can only be changed prior to cued state!
    private var pitchScale: Float? = nil
    public private (set) var pitchModulation: Bool = false
    public private(set) var isConnected: Bool = false
    
    var audioTrackState: AudioTrackState = .empty
    
    
    
    
    init(
        audioEngine: AudioEngineProtocol,
        outputConnectionPoints: [AVAudioConnectionPoint],
        fxConnectionPoints: [AVAudioConnectionPoint]
    ){
        let mixerInputConnection = AVAudioConnectionPoint(
            node: inputMixer,
            bus: 0
        )
        let audioPlayer = AudioPlayer(
            audioEngine: audioEngine,
            outputConnectionPoints: [mixerInputConnection]
        )
        
        self.fxConnectionPoints = fxConnectionPoints
        self.outputConnectionPoints = outputConnectionPoints
        self.audioPlayer = audioPlayer
        self.audioEngine = audioEngine
        
        attach(engine: audioEngine.engine)
        revertToDefaultSettings()
    }

}

// MARK: ATTACH
extension StemPlayer {
    func attach(engine: AVAudioEngine){
        engine.attach(outputMixer)
        engine.attach(pitchAU)
        engine.attach(fxMixer)
        engine.attach(inputMixer)
    }
}

// MARK: LOAD
extension StemPlayer {
    
    @available(*, deprecated, renamed: "load")
    public func cue (
        audioURL: URL,
        properties: [StemPlayer.SettableProperty],
        pitchModulation: Bool = false
    ) throws {
        return try self.load(
            audioURL: audioURL,
            properties: properties,
            pitchModulation: pitchModulation
        )
    }
    
    public func load (
        audioURL: URL,
        settings: Settings,
        pitchModulation: Bool? = nil
    ) throws {
        try self.load(
            audioURL: audioURL,
            properties: settings.properties,
            pitchModulation: pitchModulation
        )
    }
    
    public func load (
        audioURL: URL,
        properties: [StemPlayer.SettableProperty]? = nil,
        pitchModulation: Bool? = nil
    ) throws {
        let pitchModulation = pitchModulation ?? false
        try audioPlayer.load(audioURL)
        if let properties = properties {
            set(properties: properties)
        }
        self.pitchModulation = pitchModulation
        audioTrackState = .cued
    }
    
    @available(*, deprecated, renamed: "unload")
    public func uncue(){
        return self.unload()
    }
    /// Disconnects, unloads the audio file and resets all settings to default.
    public func unload(){
        if isConnected {
            disconnect()
        }
        audioPlayer.unload()
        revertToDefaultSettings()
        audioTrackState = .empty
    }
    
    /// Resets all settings, but does not unload the audioPlayer. Although, it does reset its loop.
    internal func revertToDefaultSettings(){
        set(properties: StemPlayer.defaultSettings.properties)
        self.pitchModulation = false
    }
}

// MARK: CONNECT
extension StemPlayer {
    /**
    Connects all assigned nodes.
    
     Expected signal chain:
     
     1. audioPlayer to input mixer (where mute occurs)
     
     2. input mixer optionally to pitch effect and output mixer, or directly to
     input mixer to output mixer (where volume and pan occurs)
     
     3. output mixer is sent to main output declared in init and fxMixer
     
     4. fxMixer is sent to main fx output declared in init.
    
    - Throws: Throws if set connection points are not connectable or player does not connect.
    */
    public func connect() throws {
        let fxMixerInPoint = AVAudioConnectionPoint(node: fxMixer, bus: 0)
        
        var outPoints = outputConnectionPoints
        outPoints.append(fxMixerInPoint)
        
        let verifiedOutPoints = try AVAudioConnectionPoint.connectable(
            outPoints
        )
        let fxPoints = try AVAudioConnectionPoint.connectable(
            fxConnectionPoints
        )
        
        if !audioPlayer.isConnected {
            try audioPlayer.connect()
        }
        if pitchModulation {
            engine.connect(inputMixer, to: pitchAU, format: audioFormat)
            engine.connect(pitchAU, to: outputMixer, format: audioFormat)
        } else {
            engine.connect(inputMixer, to: outputMixer, format: audioFormat)
        }
        engine.connect(outputMixer, to: verifiedOutPoints, fromBus: 0, format: audioFormat)
        engine.connect(fxMixer, to: fxPoints, fromBus: 0, format: audioFormat)
        self.isConnected = checkConnection()
        // MAYBE DISCONNECT IF NOT isConnected?
    }
    
    /// Disconnects all nodes and sets isConnected var. Pitch modulation effect is disconnected if it is attached regardless of whether pitch modulation is enabled or not.
    public func disconnect(){
        if audioPlayer.isConnected {
            audioPlayer.disconnect()
        }
        engine.disconnectNodeOutput(inputMixer)
        if pitchAU.isOutputConnected {
            engine.disconnectNodeOutput(pitchAU)
        }
        engine.disconnectNodeOutput(fxMixer)
        engine.disconnectNodeOutput(outputMixer)
        self.isConnected = checkConnection()
    }
    
    private func checkConnection() -> Bool {
        guard audioPlayer.isConnected,
            inputMixer.isOutputConnected,
            fxMixer.isOutputConnected,
            outputMixer.isOutputConnected
        else { return false }
        if pitchModulation {
            guard pitchAU.isOutputConnected else { return false }
        }
        return true
    }
}
 

// MARK: PROPERTIES
extension StemPlayer {
    
    public func set(properties: [StemPlayer.SettableProperty]) {
        for property in properties {
            set(property: property)
        }
    }
    
    public func set(property: StemPlayer.SettableProperty){
        switch property {
        case .FXSend(let postFaderRatio): self.fxSend = postFaderRatio
        case .panControl(let value): self.panControl = value
        case .volume(let value): self.volume = value
        case .pitchModulation(let rate): self.pitchRate = rate
        case .loop(let value): self.loop = value
        case .mute(let muted): self.isMuted = muted
        case .pan(let pan): self.pan = pan
        }
    }
    public var pitchRate: PitchRate {
        get { return pitchAU.rate }
        set { pitchAU.rate = newValue }
    }
    public var isMuted: Bool {
        get { return inputMixer.volume == 0 }
        set { inputMixer.volume = newValue ? 0 : 1 }
    }
    /// Send to FX Bus. This is a post fader (after the channel volume and pan in the signal chain.)
    public var fxSend: Volume {
        get { return fxMixer.volume }
        set { fxMixer.volume = newValue }
    }
    public var pan: Pan {
        get { return outputMixer.pan }
        set { outputMixer.pan = newValue }
    }
    public var panControl: PanControl {
        get { return Settings.panControl(from: self.pan) }
        set { self.pan = Settings.pan(from: newValue) }
    }
    public var volume: Volume {
        get { return self.outputMixer.volume }
        set { self.outputMixer.volume = newValue }
    }
    public var loop: Bool {
        get { return self.audioPlayer.loop }
        set { self.audioPlayer.loop = newValue }
    }
}

// MARK: CALCULATED VARS
extension StemPlayer {
    var engine: AVAudioEngine {
        return audioEngine.engine
    }
    var audioFormat: AVAudioFormat? {
        return audioPlayer.audioFormat
    }
    public var settings: Settings {
        return Settings(
            volume: self.volume,
            pan: self.pan,
            isMuted: self.isMuted,
            fxSend: self.fxSend,
            loop: self.loop,
            pitchRate: self.pitchRate
        )
    }
}


