//
//  Playback Engine.swift
//  RPG Music
//
//  Created by William Piotrowski on 3/5/19.
//  Copyright © 2019 William Piotrowski. All rights reserved.
//


import AVFoundation

public class AudioPlayback {
    private let masterMixer = AVAudioMixerNode()
    private let defaultAudioFormat: AVAudioFormat?
    private let outputConnectionPoints: [AVAudioConnectionPoint]
    private let sequencerA: AudioSequencer
    private let sequencerB: AudioSequencer
    public let audioEngine: AudioEngine
    private var primarySequencer: AudioSequencer
    public let effects: AudioEffects
    private(set) var isConnected: Bool = false
    public let speechTriggeredPlayer: AudioPlayer
    
    public init(
        audioEngine: AudioEngine,
        outputConnectionPoints: [AVAudioConnectionPoint]
    ){
        
        let defaultAudioFormat = AVAudioFormat(
            standardFormatWithSampleRate: 44100,
            channels: 2
        )
        
        let effectsConnectionPoint = AVAudioConnectionPoint(
            node: masterMixer,
            bus: 0
        )
        let sequencerAConnectionPoint = AVAudioConnectionPoint(
            node: masterMixer,
            bus: 1
        )
        let sequencerBConnectionPoint = AVAudioConnectionPoint(
            node: masterMixer,
            bus: 2
        )
        let speechPlayerConnectionPoint = AVAudioConnectionPoint(
            node: masterMixer,
            bus: 3
        )
        
        
        
        
        let effects = AudioEffects(
            audioEngine: audioEngine,
            outputConnectionPoints: [effectsConnectionPoint],
            defaultAudioFormat: defaultAudioFormat
        )
        let sequencerA = AudioSequencer(
            audioEngine: audioEngine,
            playerConnectionPoint: sequencerAConnectionPoint,
            fxConnectionPoint: effects.getInputConnectionPoint(bus: 0)
        )
        let sequencerB = AudioSequencer(
            audioEngine: audioEngine,
            playerConnectionPoint: sequencerBConnectionPoint,
            fxConnectionPoint: effects.getInputConnectionPoint(bus: 1)
        )
        let speechTriggeredPlayer = AudioPlayer(
            audioEngine: audioEngine,
            outputConnectionPoints: [speechPlayerConnectionPoint]
        )
        
        
        self.audioEngine = audioEngine
        self.defaultAudioFormat = defaultAudioFormat
        self.outputConnectionPoints = outputConnectionPoints
        self.speechTriggeredPlayer = speechTriggeredPlayer
        self.sequencerA = sequencerA
        self.sequencerB = sequencerB
        self.effects = effects
        
        self.primarySequencer = sequencerA
        attach()
    }
}

// PRIVATE METHODS
extension AudioPlayback {
    private func attach(){
        engine.attach(masterMixer)
    }
}

// PUBLIC METHODS
extension AudioPlayback {
    public func connect() throws {
        let outPoints = try AVAudioConnectionPoint.connectable(outputConnectionPoints)
        engine.connect(masterMixer, to: outPoints, fromBus: 0, format: defaultAudioFormat)
        try effects.connect()
        isConnected = checkConnection()
    }
    func disconnect(){
        sequencerA.disconnect()
        sequencerB.disconnect()
        engine.disconnectNodeOutput(masterMixer)
        isConnected = checkConnection()
    }
    func checkConnection() -> Bool{
        guard
            sequencerA.isConnected,
            sequencerB.isConnected,
            effects.isConnected,
            masterMixer.isOutputConnected
            else { return false }
        return true
    }
    public func setPrimary(sequencer: AudioSequencer){
        primarySequencer.stop()
        primarySequencer.disconnect()
        primarySequencer = sequencer
    }
}

extension AudioPlayback: AudioEngineControllerProtocol {
    public var isRunning: Bool {
        return (sequencerA.isPlaying || sequencerB.isPlaying)
    }
    public func stop(){
        sequencerA.stop()
        sequencerB.stop()
    }
}

// CALCULATED VARS
extension AudioPlayback {
    private var engine: AVAudioEngine {
        return audioEngine.engine
    }
    public var secondarySequencer: AudioSequencer {
        let secondarySeq = (primarySequencer === sequencerA) ? sequencerB : sequencerA
        //let secondarySeq = privateSecondarySequencer
        secondarySeq.reset()
        return secondarySeq
    }
    private var privateSecondarySequencer: AudioSequencer {
        if case .empty = sequencerA.sequencerState {
            return sequencerA
        }
        if case .empty = sequencerB.sequencerState {
            return sequencerB
        }
        if sequencerA.isPlaying {
            return sequencerB
        }
        if sequencerB.isPlaying {
            return sequencerA
        }
        return sequencerB
    }
}
