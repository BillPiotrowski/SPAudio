//
//  AudioPlayer.swift
//  WPAudio
//
//  Created by William Piotrowski on 7/1/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import AVFoundation
import ReactiveSwift

// ADD CONNECT ON BACKGROUND THREAD PROMISE??

public class AudioPlayer {
    internal let avAudioPlayerNode = AVAudioPlayerNode()
    private let audioEngine: AudioEngineProtocol
    private let outputConnectionPoints: [AVAudioConnectionPoint]
    internal private(set) var audioFile: AVAudioFile? = nil
    public private(set) var isConnected: Bool = false
    internal private(set) var isScheduled = false
    /// A variable that sets if player will replay audio file after it completes.
    public var loop = true
    
    private let transportStateInput: Signal<AudioTransportState, Never>.Observer
    public let audioTransportState: Property<AudioTransportState>
    
    private let audioPlayerStateInput: Signal<AudioPlayer.State, Never>.Observer
    public let audioPlayerStateProperty: Property<AudioPlayer.State>

    
    
    
    public init(
        audioEngine: AudioEngineProtocol,
        outputConnectionPoints: [AVAudioConnectionPoint]
    ){
        let initialAudioPlayerState = AudioPlayer.State.standby
        let intitialTransportState = AudioTransportState.stopped
        
        
        let audioTransportStatePipe = Signal<AudioTransportState, Never>.pipe()
        let audioTransportStateProperty = Property(
            initial: intitialTransportState,
            then: audioTransportStatePipe.output
        )
        let audioPlayerStatePipe = Signal<AudioPlayer.State, Never>.pipe()
        let audioPlayerStateProperty = Property(
            initial: initialAudioPlayerState,
            then: audioPlayerStatePipe.output
        )
        
        self.audioPlayerStateInput = audioPlayerStatePipe.input
        self.audioPlayerStateProperty = audioPlayerStateProperty
        self.transportStateInput = audioTransportStatePipe.input
        self.audioTransportState = audioTransportStateProperty
        self.audioEngine = audioEngine
        self.outputConnectionPoints = outputConnectionPoints
        
        self.attach(engine: engine)
    }
}

// MARK: ATTACH
extension AudioPlayer {
    private func attach(engine: AVAudioEngine){
        engine.attach(avAudioPlayerNode)
    }
}

// MARK: LOAD / UNLOAD
extension AudioPlayer {
    @available(*, deprecated, renamed: "load")
    public func cue(
        _ audioFileURL: URL, autoPlay: Bool = false
    ) throws {
        return try self.load(audioFileURL, autoPlay: autoPlay)
    }
    
    /// Cues the player with a local audio file url.
    public func load(
        _ audioFileURL: URL,
        autoPlay: Bool? = nil
    ) throws {
        let autoPlay = autoPlay ?? false
        unload()
        do {
            audioFile = try AVAudioFile(forReading: audioFileURL)
        } catch {
            throw Error.couldNotLoadAudio(url: audioFileURL)
        }
        self.audioPlayerStateInput.send(value: .cued(transport: self))
        if autoPlay {
            try? play()
        }
    }
    
    @available(*, deprecated, renamed: "unload")
    public func uncue(){
        return self.unload()
    }
    
    /// Stops playback, disconnects and removes any audiofile that has been loaded. Sets state to standby.
    public func unload(){
        if (isPlaying) { stop() }
        if (isConnected) { disconnect() }
        audioFile = nil
        self.loop = true
        self.audioPlayerStateInput.send(value: .standby)
    }
}

// MARK: CONNECTION
extension AudioPlayer {
    
    public func connect() throws {
        guard let audioFormat = audioFormat else {
            throw Error.connectNoFormat
        }
        let filteredOutputConnectionPoints = try AVAudioConnectionPoint.connectable(outputConnectionPoints)
        engine.connect(
            avAudioPlayerNode,
            to: filteredOutputConnectionPoints,
            fromBus: 0,
            format: audioFormat
        )
        self.isConnected = self.outputIsConnected
    }
    
    public func disconnect(){
        if isPlaying {
            avAudioPlayerNode.stop()
        }
        engine.disconnectNodeOutput(avAudioPlayerNode)
        self.isConnected = self.outputIsConnected
    }
    
    private var outputIsConnected: Bool {
        return engine.outputConnectionPoints(
            for: avAudioPlayerNode,
            outputBus: 0
        ).count > 0
    }
}

// MARK: SCHEDULING
extension AudioPlayer {
    internal func scheduleAudioFile() throws {
        guard let audioFile = audioFile else {
            throw Error.scheduleNoAudioFile
        }
        avAudioPlayerNode.scheduleFile(
            audioFile,
            at: nil,
            completionHandler: audioFileCompletedPlaying
        )
        isScheduled = true
    }
    
    private func audioFileCompletedPlaying(){
        if loop && transportState == .playing {
            try? play()
        }
    }
}


// MARK: AudioPlayerTransport
extension AudioPlayer: AudioPlayerTransport {
    public var isPreparedToPlay: Bool {
        guard isConnected else { return false }
        return isScheduled
    }
    public func prepareToPlay() throws {
        if !isConnected { try connect() }
        if !isScheduled { try scheduleAudioFile() }
    }
    public func play() throws {
        if !isPreparedToPlay {
            try prepareToPlay()
        }
        if !audioEngine.isRunning {
            try audioEngine.start()
        }
        avAudioPlayerNode.play()
        isScheduled = false
        self.transportStateInput.send(value: .playing)
    }
    public func stop(){
        avAudioPlayerNode.stop()
        self.transportStateInput.send(value: .stopped)
        isScheduled = false
    }
    public func pause(){
        avAudioPlayerNode.pause()
        self.transportStateInput.send(value: .paused)
    }
    public func playStopToggle(){
        switch isPlaying {
        case true: stop()
        case false: try? play()
        }
    }
    public var isPlaying: Bool {
        return avAudioPlayerNode.isPlaying
    }
}



// MARK: CALCULATED VARS
extension AudioPlayer {
//    @available(*, deprecated, message: "This is going to be made internal.")
//    public var node: AVAudioNode {
//        return avAudioPlayerNode
//    }
    
    /// The format of the audioFile if one has been successfully loaded.
    public var audioFormat: AVAudioFormat? {
        return audioFile?.processingFormat
    }
    var url: URL? {
        return audioFile?.url
    }
    
    public var playerState: AudioPlayer.State {
        return audioPlayerStateProperty.value
    }
    public var transportState: AudioTransportState {
        return audioTransportState.value
    }
    private var engine: AVAudioEngine {
        return audioEngine.engine
    }
}



