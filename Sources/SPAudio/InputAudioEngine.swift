//
//  InputAudioEngine.swift
//  Scorepio
//
//  Created by William Piotrowski on 2/8/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import AVFoundation


public class InputAudioEngine {
    public let audioEngine: AudioEngine
    let outputConnectionPoints: [AVAudioConnectionPoint]
    public let recordedDialogMixer: AVAudioMixerNode
    
    public let recordedDialogPlayer: AudioPlayer
    public let meter: AudioMeter
    
    public init(
        audioEngine: AudioEngine,
        outputConnectionPoints: [AVAudioConnectionPoint]
    ){
        let recordedDialogMixer = AVAudioMixerNode()
        audioEngine.engine.attach(recordedDialogMixer)
        let mixinginput = AVAudioConnectionPoint(node: recordedDialogMixer, bus: 2)
        
        
        //audioEngine.engine.connect(recordedDialogMixer, to: outputConnectionPoints, fromBus: 0, format: nil)
        //recordedDialogMixer.connect(to: outputConnectionPoints[0])
        
        self.audioEngine = audioEngine
        self.outputConnectionPoints = outputConnectionPoints
        
        self.meter = AudioMeter(audioEngine: audioEngine)
        
        self.recordedDialogPlayer = AudioPlayer(
            audioEngine: audioEngine,
            outputConnectionPoints: [mixinginput]
        )
        audioEngine.engine.connect(recordedDialogMixer, to: outputConnectionPoints, fromBus: 0, format: nil)
        self.recordedDialogMixer = recordedDialogMixer
    }
}
// MARK: AUDIO ENGINE PROTOCOL
extension InputAudioEngine: AudioEngineControllerProtocol {
    /// Boolean to check if child audio nodes are running. Conforms with AudioEngineProtocol
    public var isRunning: Bool {
        return (recordedDialogPlayer.isPlaying || meter.isRunning)
    }
    public func stop(){
        meter.stop()
        recordedDialogPlayer.stop()
    }
}

// MARK: AUDIO ATTACH
extension InputAudioEngine {
    func attach(_ engine: AVAudioEngine){
    }
}
