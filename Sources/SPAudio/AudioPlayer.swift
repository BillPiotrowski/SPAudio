//
//  AudioPlayer.swift
//  WPAudio
//
//  Created by William Piotrowski on 7/1/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import AVFoundation
import AVKit
import ReactiveSwift

public class AudioPlayer: Observable2 {
    private let player = AVAudioPlayerNode()
    private let audioEngine: AudioEngineProtocol
    private var engine: AVAudioEngine {
        return audioEngine.engine
    }
    private let outputConnectionPoints: [AVAudioConnectionPoint]
    private var audioFile: AVAudioFile? = nil
    private var connected: Bool = false
    private var isScheduled = false
    /// A variable that sets if player will replay audio file after it completes.
    public var loop = true
    
    private let (transportStateOutput, transportStateInput): (Signal<AudioTransportState, Never>, Signal<AudioTransportState, Never>.Observer)
    public let audioTransportState: Property<AudioTransportState>
    
    private let audioPlayerStateInput: Signal<AudioPlayer.State, Never>.Observer
    public let audioPlayerStateProperty: Property<AudioPlayer.State>
    
    // EVENTUALLY REMOVE IF POSSIBLE!
    //internal var observations = [ObjectIdentifier : Observer2]()
    public var observations2 = [ObjectIdentifier : Observer2]()

    public var playerState: AudioPlayer.State = .standby {
        didSet {
            //print("Player State: \(playerState)")
            let observation = Observation2.audioPlayer(playerState: playerState)
            sendToObservers2(observation)
            self.audioPlayerStateInput.send(value: playerState)
        }
    }
    
    public var transportState: AudioTransportState = .stopped {
        didSet {
            let observation = Observation2.audioTransport(transportState: transportState)
            sendToObservers2(observation)
        }
    }
    
    
    public init(
        audioEngine: AudioEngineProtocol,
        outputConnectionPoints: [AVAudioConnectionPoint]
    ){
        let initialAudioPlayerState = AudioPlayer.State.standby
        let signal = Signal<AudioTransportState, Never>.pipe()
        let property = Property(
            initial: AudioTransportState.stopped,
            then: signal.output
        )
        let audioPlayerStatePipe = Signal<AudioPlayer.State, Never>.pipe()
        let audioPlayerStateProperty = Property(
            initial: initialAudioPlayerState,
            then: audioPlayerStatePipe.output
        )
        self.audioPlayerStateInput = audioPlayerStatePipe.input
        self.audioPlayerStateProperty = audioPlayerStateProperty
        self.transportStateInput = signal.input
        self.transportStateOutput = signal.output
        self.audioTransportState = property
        self.audioEngine = audioEngine
        self.outputConnectionPoints = outputConnectionPoints
        self.attach(engine: engine)
    }
    
    func attach(engine: AVAudioEngine){
        engine.attach(player)
    }
    
    /// Cues the player with a local audio file url.
    public func cue(_ audioFileURL: URL, autoPlay: Bool = false) throws {
        uncue()
        do {
            audioFile = try AVAudioFile(forReading: audioFileURL)
        } catch {
            throw Error.couldNotLoadAudio(url: audioFileURL)
        }
        playerState = .cued(transport: self)
        if autoPlay {
            play()
        }
    }
    
    public func uncue(){
        if (isPlaying) { stop() }
        if (isConnected) { disconnect() }
        audioFile = nil
        self.loop = true
        playerState = .standby
    }
    
    
    public func connect() throws {
        guard let audioFormat = audioFormat else {
            throw Error.connectNoFormat
        }
        let filteredOutputConnectionPoints = try AVAudioConnectionPoint.connectable(outputConnectionPoints)
        engine.connect(player, to: filteredOutputConnectionPoints, fromBus: 0, format: audioFormat)
        connected = checkConnection()
    }
    
    public func disconnect(){
        if isPlaying {
            player.stop()
        }
        engine.disconnectNodeOutput(player)
        connected = checkConnection()
    }
    
    private func checkConnection() -> Bool {
        return isPlayerConnected
    }
    private var isPlayerConnected: Bool {
        return engine.outputConnectionPoints(for: player, outputBus: 0).count > 0
    }
    
    private func scheduleAudioFile() throws {
        guard let audioFile = audioFile else {
            throw Error.scheduleNoAudioFile
        }
        player.scheduleFile(audioFile, at: nil, completionHandler: audioFileCompletedPlaying)
        isScheduled = true
    }
    
    private func audioFileCompletedPlaying(){
        if loop && transportState == .playing {
            play()
        }
    }
}

// MARK: CALCULATED VARS
extension AudioPlayer {
    public var isConnected: Bool {
        return connected
    }
    public var node: AVAudioNode {
        return player
    }
    public var audioFormat: AVAudioFormat? {
        return audioFile?.processingFormat
    }
    var url: URL? {
        return audioFile?.url
    }
}




extension AudioPlayer: AudioPlayerTransport {
    
    public var isPreparedToPlay: Bool {
        guard isConnected else { return false }
        return isScheduled
    }
    public func prepareToPlay() throws {
        if !isConnected { try connect() }
        if !isScheduled { try scheduleAudioFile() }
    }
    public func play(){
        if !isPreparedToPlay {
            do {
                try prepareToPlay()
            } catch {
                print("AUDIO PLAYER ERROR: \(error)")
            }
        }
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                print("COULD NOT START ENGINE: \(error)")
            }
        }
        player.play()
        isScheduled = false
        transportStateInput.send(value: .playing)
        transportState = .playing
    }
    public func stop(){
        player.stop()
        //disconnect()
        transportState = .stopped
        transportStateInput.send(value: .stopped)
        isScheduled = false
    }
    public func pause(){
        player.pause()
        transportState = .paused
        transportStateInput.send(value: .paused)
    }
    public func playStopToggle(){
        switch isPlaying {
        case true: stop()
        case false: play()
        }
    }
    public var isPlaying: Bool {
        return player.isPlaying
    }
}

// MARK: DEFINITIONS
extension AudioPlayer {
    public enum State {
        case standby
        //case loading
        //case error
        case cued(transport: AudioPlayerTransport)
    }
    
    enum Error: ScorepioError {
        case couldNotLoadAudio(url: URL)
        case connectNoFormat
        case connectNoOutput
        case scheduleNoAudioFile
        
        var message: String {
            switch self {
            case .couldNotLoadAudio(let url): return "Could not load audio file: \(url.relativeString)."
            case .connectNoFormat: return "Can not connect audio player because there is no audio format."
            case .connectNoOutput: return "Can not connect audio player because there are no output connection points."
            case .scheduleNoAudioFile: return "Could not schedule player because audio file is not defined."
            }
        }
    }
}







public protocol AudioPlayerObserver: AudioTransportObserver {
    //func playbackEngineObserver(_ activeDeckState: PlayableState)
    func audioPlayerObservation(_ playerState: AudioPlayer.State)
}
extension AudioPlayerObserver {
    func audioPlayerObservation(_ playerState: AudioPlayer.State) {}
}






public protocol AudioTransportObserver: ObserverClass2 {
    func audioTransportChanged(_ audioDeckState: AudioTransportState)
}
extension AudioTransportObserver {
    //func audioTransportChanged(_ audioDeckState: AudioTransportState) {}
}


