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


//extension AudioSequencer {
    // SHOULD PROBABLY EXTEND AUDIO PLAYER
    public class StemPlayer {
        private let inputMixer = AVAudioMixerNode()
        private let outputMixer = AVAudioMixerNode()
        //internal let pitchAU = AVAudioUnitTimePitch()
        private let pitchAU = AVAudioUnitVarispeed()
        private let fxMixer = AVAudioMixerNode()
        private let audioPlayer: AudioPlayer
        private let fxConnectionPoints: [AVAudioConnectionPoint]
        private let outputConnectionPoints: [AVAudioConnectionPoint]
        private let audioEngine: AudioEngineProtocol

        
        var engine: AVAudioEngine {
            return audioEngine.engine
        }
        
        // Can only be changed prior to cued state!
        private var pitchScale: Float? = nil
        public private (set) var pitchModulation: Bool = false
        private var connected: Bool = false
        
        var audioTrackState: AudioTrackState = .empty
        
        
        var audioFormat: AVAudioFormat? {
            return audioPlayer.audioFormat
        }
        
        private let defaults: [StemPlayer.SettableProperty] = [
            .FXSend(postFaderRatio: 0.1),
            //.gain(value: 1),
            .mute(muted: false),
            .volume(value: 0.8),
            .pan(value: 0.5),
            .pitchModulation(rate: 1),
            .loop(value: false)
        ]
        
        init(
            audioEngine: AudioEngineProtocol,
            outputConnectionPoints: [AVAudioConnectionPoint],
            fxConnectionPoints: [AVAudioConnectionPoint]
            ){
            self.fxConnectionPoints = fxConnectionPoints
            self.outputConnectionPoints = outputConnectionPoints
            self.audioPlayer = AudioPlayer(
                audioEngine: audioEngine,
                outputConnectionPoints: [
                    (AVAudioConnectionPoint(
                        node: inputMixer,
                        bus: 0
                    ))
                ]
            )
            //self.engine = audioEngine.engine
            self.audioEngine = audioEngine
            
            attach(engine: audioEngine.engine)
            revertToDefault()
        }
    
    }
//}

extension /*AudioSequencer.*/StemPlayer {
    
    // STEP 1: ATTACH / PREP (-2)
    func attach(engine: AVAudioEngine){
        engine.attach(outputMixer)
        engine.attach(pitchAU)
        engine.attach(fxMixer)
        engine.attach(inputMixer)
    }
    public func set(properties: [StemPlayer.SettableProperty]) {
        for property in properties {
            set(property: property)
        }
    }
    
    public func cue (
        audioURL: URL,
        properties: [StemPlayer.SettableProperty],
        pitchModulation: Bool = false
    ) throws {
        try audioPlayer.cue(audioURL)
        set(properties: properties)
        self.pitchModulation = pitchModulation
        audioTrackState = .cued
    }
    public func uncue(){
        if isConnected {
            disconnect()
        }
        audioPlayer.uncue()
        revertToDefault()
        audioTrackState = .empty
    }
    
    private func revertToDefault(){
        set(properties: defaults)
        self.pitchModulation = false
    }
    
    public func connect() throws {
        var tempOutPoints = outputConnectionPoints
        tempOutPoints.append(AVAudioConnectionPoint(node: fxMixer, bus: 0))
        let outPoints = try AVAudioConnectionPoint.connectable(tempOutPoints)
        let fxPoints = try AVAudioConnectionPoint.connectable(fxConnectionPoints)
        if !audioPlayer.isConnected {
            try audioPlayer.connect()
        }
        if pitchModulation {
            engine.connect(inputMixer, to: pitchAU, format: audioFormat)
            engine.connect(pitchAU, to: outputMixer, format: audioFormat)
        } else {
            engine.connect(inputMixer, to: outputMixer, format: audioFormat)
        }
        engine.connect(outputMixer, to: outPoints , fromBus: 0, format: audioFormat)
        engine.connect(fxMixer, to: fxPoints, fromBus: 0, format: audioFormat)
        connected = checkConnection()
    }
    
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
        connected = checkConnection()
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
    public var isConnected: Bool{
        return connected
    }
    
    public enum SettableProperty {
        case FXSend(postFaderRatio: Float)
        case pan(value: Float)
        //case gain(value: Float)
        case volume(value: Float)
        case pitchModulation(rate: Float)
        case loop(value: Bool)
        case mute(muted: Bool)
    }
    
    public func set(property: StemPlayer.SettableProperty){
        switch property {
        case .FXSend(let postFaderRatio): fxMixer.volume = postFaderRatio
        case .pan(let value): outputMixer.pan = value * 2 - 1
        //case .gain(let value): inputMixer.volume = value
        case .volume(let value): outputMixer.volume = value
        case .pitchModulation(let rate): pitchAU.rate = rate
        case .loop(let value): audioPlayer.loop = value
        case .mute(let muted): inputMixer.volume = muted ? 0 : 1
        }
    }
    public var isMuted: Bool {
        return (inputMixer.volume == 0) ? true : false
    }
}

// MARK: TRANSPORT
extension StemPlayer: AudioPlayerTransport{
    
    public var audioTransportState: Property<AudioTransportState> {
        return audioPlayer.audioTransportState
    }
    
    public var observations2: [ObjectIdentifier : Observer2] {
        get {
            return audioPlayer.observations2
        } set (val) {
            audioPlayer.observations2 = val
        }
    }
    public var transportState: AudioTransportState {
        return audioPlayer.transportState
    }
    
    public var isPlaying: Bool {
        return audioPlayer.isPlaying
    }
    
    public var isPreparedToPlay: Bool {
        guard isConnected else { return false }
        return audioPlayer.isPreparedToPlay
    }
    
    public func play() {
        if !isPreparedToPlay {
            do {
                try prepareToPlay()
            } catch {
                print("AUDIO PLAYER ERROR: \(error)")
            }
        }
        audioPlayer.play()
    }
    
    public func stop() {
        audioPlayer.stop()
        //disconnect()
    }
    public func pause() {
        audioPlayer.pause()
    }
    
    public func playStopToggle() {
        audioPlayer.playStopToggle()
    }
    
    public func prepareToPlay() throws {
        if !isConnected { try connect() }
        if !audioPlayer.isPreparedToPlay { try audioPlayer.prepareToPlay() }
    }
}



// MARK: DEFINITIONS
enum AudioTrackState {
    case empty
    //case loading
    case cued
}
