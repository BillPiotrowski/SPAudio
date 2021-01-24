//
//  InputAudioEngine.swift
//  Scorepio
//
//  Created by William Piotrowski on 2/8/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import AVFoundation
import SPCommon


public class InputAudioEngine {
    public let audioEngine: AudioEngine
    let outputConnectionPoints: [AVAudioConnectionPoint]
    public let recordedDialogMixer: AVAudioMixerNode
    
    public let speechRecognition: SpeechRecognition
    
    public let recordedDialogPlayer: AudioPlayer
    // MAKE INTERNAL
    public let meter: AudioMeter
    
    public init(
        audioEngine: AudioEngine,
        outputConnectionPoints: [AVAudioConnectionPoint]
    ){
        let recordedDialogMixer = AVAudioMixerNode()
        audioEngine.engine.attach(recordedDialogMixer)
        let mixinginput = AVAudioConnectionPoint(node: recordedDialogMixer, bus: 2)
        
        
        let speechRecognition = SpeechRecognition(
            audioSession: audioEngine.session
        )
        
        self.speechRecognition = speechRecognition
        self.audioEngine = audioEngine
        self.outputConnectionPoints = outputConnectionPoints
        
        self.meter = AudioMeter(
            audioEngine: audioEngine,
            speechRecognition: speechRecognition
        )
        
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
    /// Duration of the audio meter as a ratio from 0-1
    public var meterSpeedRatio: MeterTimeRatio.Ratio {
        get { return meter.speedRatio }
        set { self.meter.speedRatio = newValue }
    }
}

extension InputAudioEngine {
    public func tapDeviceInput() throws -> (AudioMeter, AudioInputDevice){
        guard let inputDevice = audioEngine.inputDevice else {
            throw InputEngineError.noDeviceInput
        }
        meter.attach(node: inputDevice.avNode)
        return (meter, inputDevice)
    }
    
    public func tapDialogPlayer() -> (AudioMeter, AudioPlayer) {
        meter.attach(node: recordedDialogPlayer.avAudioPlayerNode)
        return (meter, recordedDialogPlayer)
    }
}

// MARK: AUDIO ATTACH
extension InputAudioEngine {
    func attach(_ engine: AVAudioEngine){
    }
}


private enum InputEngineError: ScorepioError {
    case noDeviceInput
    
    var message: String {
        switch self {
        case .noDeviceInput: return "There are no device inputs. Can not attach meter."
        }
    }
}
