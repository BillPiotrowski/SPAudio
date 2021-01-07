//
//  File.swift
//
//
//  Created by William Piotrowski on 1/5/21.
//

import AVFoundation


class VCA {
    private unowned let audioEngine: AudioEngine
    private let outputMixer: AVAudioMixerNode
    private let destination: AVAudioConnectionPoint
    public private (set) var isConnected: Bool = false
    public private (set) var isPlaying: Bool = false
    public var maxVolume: Float = VCA.maxVolumeDefault
    
    internal static let maxVolumeDefault: Float = 0.8
    
    init(
        wire to: AVAudioConnectionPoint,
        audioEngine: AudioEngine
    ){
        let outputMixer = AVAudioMixerNode()
        
        self.audioEngine = audioEngine
        self.outputMixer = outputMixer
        self.destination = to
        
        self.outputMixer.outputVolume = 0
        
        self.attach()
    }
}

// MARK: ATTACH
extension VCA {
    private func attach(){
        self.audioEngine.engine.attach(self.outputMixer)
    }
}

// MARK: COMPUTED VARS
extension VCA {
    private var audioFormat: AVAudioFormat {
        return audioEngine.engine.outputNode.inputFormat(forBus: 0)
    }
}

// MARK: CONNECT
extension VCA {
    func connect() throws {
        guard !isConnected else {
            throw NSError(domain: "Trying to connect, but already connected", code: 1, userInfo: nil)
        }
        audioEngine.engine.connect(
            outputMixer,
            to: [destination],
            fromBus: 0,
            format: audioFormat
        )
        self.isConnected = self.checkConnection()
    }
    
    func disconnect(){
        if isPlaying {
            self.stop()
        }
        audioEngine.engine.disconnectNodeOutput(outputMixer)
        self.isConnected = self.checkConnection()
    }
    
    func checkConnection() -> Bool{
        return outputMixer.isOutputConnected
    }
}


// MARK: TRANSPORT / ON / OFF
extension VCA {
    func play() throws {
        if !isConnected {
            try self.connect()
        }
        self.outputMixer.outputVolume = maxVolume
        self.isPlaying = true
        
    }
    func stop() {
        self.outputMixer.outputVolume = 0
        self.isPlaying = false
    }
    
}

// MARK: PUBLIC VAR
extension VCA {
    // Ideally, this would not be exposed.
    var node: AVAudioNode {
        return self.outputMixer
    }
}
