//
//  Synth.swift
//  Swift Synth
//
//  Created by Grant Emerson on 7/21/19.
//  Copyright © 2019 Grant Emerson. All rights reserved.
//

import AVFoundation

class OscillatorNode {
    private let outputMixer: AVAudioMixerNode
    private let destination: AVAudioConnectionPoint
    // MARK: Properties
    
//    public static let shared = Synth()
//
//    public var volume: Float {
//        set {
//            audioEngine.mainMixerNode.outputVolume = newValue
//        }
//        get {
//            audioEngine.mainMixerNode.outputVolume
//        }
//    }
    
    public var frequencyRampValue: Float = 0
    
    public var frequency: Float = 440 {
        didSet {
            if oldValue != 0 {
                frequencyRampValue = frequency - oldValue
            } else {
                frequencyRampValue = 0
            }
        }
    }

    private let engine: AudioEngine
    private var audioEngine: AVAudioEngine {
        return engine.engine
    }
    
    private var time: Float = 0
    private let sampleRate: Double
    private let deltaTime: Float
    
    private var signal: AudioSignal
    private let inputFormat: AVAudioFormat?
    
    public private(set) var isConnected: Bool = false
    
    private var isRunning: Bool = false
    
    @available(iOS 13.0, *)
    private lazy var sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList in
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
                
        let localRampValue = self.frequencyRampValue
        let localFrequency = self.frequency - localRampValue
        
        let period = 1 / localFrequency

        for frame in 0..<Int(frameCount) {
            let percentComplete = self.time / period
            let sampleVal = self.signal(localFrequency + localRampValue * percentComplete, self.time)
            self.time += self.deltaTime
            self.time = fmod(self.time, period)
            
            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                buf[frame] = sampleVal
            }
        }
        
        self.frequencyRampValue = 0
        
        return noErr
    }
    
    
    // MARK: Init
    
    init(
        wire to: AVAudioConnectionPoint,
        engine: AudioEngine,
        signal: @escaping AudioSignal = Oscillator.sine
    ) {
        let audioEngine = engine.engine
        let outputMixer = AVAudioMixerNode()
        
//        let mainMixer = audioEngine.mainMixerNode
//        let outputNode = audioEngine.outputNode
        let format = audioEngine.outputNode.inputFormat(forBus: 0)
        
        
        let inputFormat = AVAudioFormat(
            commonFormat: format.commonFormat,
            sampleRate: format.sampleRate,
            channels: 1,
            interleaved: format.isInterleaved
        )
        
        
        sampleRate = format.sampleRate
        deltaTime = 1 / Float(sampleRate)
        
        self.signal = signal
        self.engine = engine
        self.destination = to
        self.inputFormat = inputFormat
        self.outputMixer = outputMixer
        
        // PROPERTY INIT COMPLETE
        
//        if #available(iOS 13.0, *) {
//            audioEngine.attach(sourceNode)
//        } else {
//            // Fallback on earlier versions
//        }
//        if #available(iOS 13.0, *) {
//            audioEngine.connect(sourceNode, to: mainMixer, format: inputFormat)
//        } else {
//            // Fallback on earlier versions
//        }
//        audioEngine.connect(mainMixer, to: outputNode, format: nil)
//        mainMixer.outputVolume = 0
        self.attach()
//        self.outputMixer.outputVolume = 0
        
//        do {
//            try audioEngine.start()
//        } catch {
//            print("Could not start engine: \(error.localizedDescription)")
//        }
        
    }
    
    // MARK: Public Functions
    
    public func setWaveformTo(_ signal: @escaping AudioSignal) {
        self.signal = signal
    }
    
}

// MARK: COMPUTED VARS
extension OscillatorNode {
    private var audioFormat: AVAudioFormat {
        return audioEngine.outputNode.inputFormat(forBus: 0)
    }
}


// MARK: ATTACH
extension OscillatorNode {
    private func attach(){
        if #available(iOS 13.0, *) {
            audioEngine.attach(sourceNode)
        }
        audioEngine.attach(outputMixer)
    }
}

// MARK: CONNECT
extension OscillatorNode {
    func connect() throws {
        guard !isConnected else {
            throw NSError(domain: "Trying to connect, but already connected", code: 1, userInfo: nil)
        }
        if #available(iOS 13.0, *) {
            try audioEngine.connect(
                from: sourceNode,
                to: outputMixer,
                fromBus: 0,
                toBus: 0,
                format: inputFormat
            )
        } else {
            // Fallback on earlier versions
        }
        audioEngine.connect(
            outputMixer,
            to: [destination],
            fromBus: 0,
            format: audioFormat
        )
        self.isConnected = self.checkConnection()
    }
    
    func disconnect(){
        if #available(iOS 13.0, *) {
            audioEngine.disconnectNodeOutput(sourceNode)
        }
        audioEngine.disconnectNodeOutput(outputMixer)
        self.isConnected = self.checkConnection()
    }
    
    func checkConnection() -> Bool{
        if #available(iOS 13.0, *) {
            guard sourceNode.isOutputConnected else { return false }
        }
        return outputMixer.isOutputConnected
    }
}

