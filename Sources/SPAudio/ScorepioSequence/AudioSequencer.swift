//
//  Deck.swift
//  RPG Music
//
//  Created by William Piotrowski on 4/13/19.
//  Copyright © 2019 William Piotrowski. All rights reserved.
//

import AVFoundation
import AudioKit
import CoreAudioKit
import CoreAudio
import CoreMIDI
import CoreAudioKit
import ReactiveSwift
import SPCommon

public class AudioSequencer /*: Observable2 */{
    /// Final mixerNode before output.
    internal let mainMaster = AVAudioMixerNode()
    
    // Also where the synth fx should go??
    /// MixerNode that combines stemFXMixer to a new signal. This is sent to the sequencer output fxConnectionPoints.
    internal let fxMaster = AVAudioMixerNode()
    
    /// MixerNode that combines the stemMixer with the synthNode output. Sent to the mainMaster.
    internal let outputMixer = AVAudioMixerNode()
    
    /// MixerNode that combines all stem outputs into a single signal and sends to outputMixer
    internal let stemMixer: AVAudioMixerNode
    
    /// MixerNode that combines all stem fx sends into one signal.
    internal let stemFXMixer: AVAudioMixerNode
    
    private let playerConnectionPoints: [AVAudioConnectionPoint]
    private let fxConnectionPoints: [AVAudioConnectionPoint]
    private let audioEngine: AudioEngineProtocol
    
    public static let trackCount: Int = 9
    public static let usesSynthDefault: Bool = false
    public static let masterVolumeDefault: Volume = 1
    
    public let stemPlayers: [StemPlayer]
    internal private(set) var activeStemPlayers: [StemPlayer] = []
    // WHY IS THIS OPTIONAL??
    public private(set) var sequencer: AppleSequencer
    public private(set) var isConnected: Bool = false
    public private(set) var usesSynth: Bool
    
    private let transportStateInput: Signal<AudioTransportState, Never>.Observer
    public let audioTransportState: Property<AudioTransportState>
    
    private let sequencerStateInput: Signal<State, Never>.Observer
    public let sequencerStateProperty: Property<State>
    
    public let synth: Synth
    
    public init(
        audioEngine: AudioEngineProtocol,
        playerConnectionPoint: AVAudioConnectionPoint,
        fxConnectionPoint: AVAudioConnectionPoint
    ){
        let stemMixer = AVAudioMixerNode()
        let fxMixer = AVAudioMixerNode()
        let synth = Synth()
        
        let initialTransportState = AudioTransportState.stopped
        let initialSequencerState = State.empty
        
        let signal = Signal<AudioTransportState, Never>.pipe()
        let property = Property(
            initial: initialTransportState,
            then: signal.output
        )
        
        let sequencerStateSignal = Signal<State, Never>.pipe()
        let sequencerStateProperty = Property(
            initial: initialSequencerState,
            then: sequencerStateSignal.output
        )
        
        let stemPlayers = AudioSequencer.stemPlayers(
            from: AudioSequencer.trackCount,
            audioEngine: audioEngine,
            outputMixer: stemMixer,
            fxMixer: fxMixer
        )
        
        let sequencer = AppleSequencer()
        
        self.sequencerStateInput = sequencerStateSignal.input
        self.sequencerStateProperty = sequencerStateProperty
        self.sequencer = sequencer
        self.synth = synth
        self.playerConnectionPoints = [playerConnectionPoint]
        self.fxConnectionPoints = [fxConnectionPoint]
        self.audioEngine = audioEngine
        self.transportStateInput = signal.input
        self.audioTransportState = property
        self.stemMixer = stemMixer
        self.stemFXMixer = fxMixer
        self.stemPlayers = stemPlayers
        self.usesSynth = AudioSequencer.usesSynthDefault
        
        attach()
        self.reset()
        //synth.connect(to: audioEngine.outputMixer)
    }
}

// MARK:ATTACH ENGINE
extension AudioSequencer {
    func attach(){
        engine.attach(outputMixer)
        engine.attach(stemMixer)
        engine.attach(stemFXMixer)
        engine.attach(mainMaster)
        engine.attach(fxMaster)
        engine.attach(synth.avAudioNode)
    }
}

// MARK: LOAD / RESET
extension AudioSequencer {
    // Could create a function: prepare() -> (Sequencer, [StemPlayer], etc.) to provide the cartridge all of the required properties and then have it call: prepareComplete(Sequencer: activeStemPlayers, etc.) to more solidly lock in loading.
    
    /// Allows sequencer to know that loading is complete and ready to begin using and changes state to .cued. Sets active stem players. Stem players should not be loaded or unloaded once this function has been called because it can cause connection errors.
    public func loadingComplete(usesSynth: Bool? = nil){
        self.usesSynth = usesSynth ?? AudioSequencer.usesSynthDefault
        self.activeStemPlayers = AudioSequencer.activeStemPlayers(
            from: self.stemPlayers
        )
        self.masterVolume = AudioSequencer.masterVolumeDefault
        self.sequencerStateInput.send(value: .cued)
    }
    
    public func reset() {
        if self.isPlaying {
            self.stop()
        }
        if isConnected {
            disconnect()
        }
        self.usesSynth = AudioSequencer.usesSynthDefault
        
        // CLEAR PREVIOUS SEQ?
        self.sequencer = AppleSequencer()
        
        for stemPlayer in activeStemPlayers {
            stemPlayer.unload()
        }
        self.activeStemPlayers = []
        
        set(properties: AudioSequencer.defaultSettings.properties)
        self.sequencerStateInput.send(value: .empty)
    }
}

// MARK: CONNECT
extension AudioSequencer {
    func connect() throws {
        guard !isConnected else {
            throw NSError(domain: "Trying to connect, but already connected", code: 1, userInfo: nil)
        }
        
        // MAKE SURE EVERYTHING IS DISCONNECTED?? MAY NOT BE NECESSARY
        self.disconnect()
        // BETTER WAY TO HANDLE audioFormat?
        let audioFormat = stemPlayers[0].audioFormat ?? synth.avAudioNode.outputFormat(forBus: 0)
        
        if self.usesSynth {
            engine.connect(
                synth.avAudioNode,
                to: outputMixer,
                fromBus: 0,
                toBus: 2,
                format: audioFormat
            )
        }
        
        //ORDER IS IMPORTANT. PUTTING STEMS AFTER MIXER WILL BREAK WITH PITCH AUDIO UNIT!!!!!
        for stemPlayer in activeStemPlayers {
            try stemPlayer.connect()
        }
        let connectableFXOuts = try AVAudioConnectionPoint.connectable(
            fxConnectionPoints
        )
        let connectableOuts = try AVAudioConnectionPoint.connectable(
            playerConnectionPoints
        )
        
        try engine.connect(from: stemFXMixer, to: fxMaster, fromBus: 0, toBus: 0, format: audioFormat)
        engine.connect(stemMixer, to: outputMixer, fromBus: 0, toBus: 0, format: audioFormat)
        engine.connect(outputMixer, to: mainMaster, fromBus: 0, toBus: 0, format: audioFormat)
        
        engine.connect(fxMaster, to: connectableFXOuts, fromBus: 0, format: audioFormat)
        engine.connect(mainMaster, to: connectableOuts, fromBus: 0, format: audioFormat)
        self.isConnected = checkConnection()
        // SHOULD DISCONNECT IF ONE IS FALSE??
    }
    
    public func disconnect(){
        if isPlaying {
            stop()
        }
        for stemPlayer in activeStemPlayers {
            stemPlayer.disconnect()
        }
        if synth.avAudioNode.isOutputConnected {
            engine.disconnectNodeOutput(synth.avAudioNode)
        }
        engine.disconnectNodeOutput(stemFXMixer)
        engine.disconnectNodeOutput(stemMixer)
        engine.disconnectNodeOutput(outputMixer)
        engine.disconnectNodeOutput(mainMaster)
        engine.disconnectNodeOutput(fxMaster)
        // NOT SURE THIS IS NECESSARY?
        //engine.disconnectNodeInput(outputMixer)
        self.isConnected = checkConnection()
    }
    
    
    //Maybe just make this a variable that is changed when connected / disconnected instead of checking manually?
    func checkConnection() -> Bool{
        guard stemFXMixer.isOutputConnected,
            stemMixer.isOutputConnected,
            outputMixer.isOutputConnected,
            fxMaster.isOutputConnected,
            mainMaster.isOutputConnected
            else {
                return false
        }
        if self.usesSynth && !synth.avAudioNode.isOutputConnected {
            return false
        }
        for stemPlayer in activeStemPlayers {
            guard stemPlayer.isConnected else { return false }
        }
        return true
    }
}


    
    // ADD PROTECTION TO MAKE SURE IT IS CUED??
// MARK: TRANSPORT
extension AudioSequencer: AudioPlayerTransport {
    public var isPreparedToPlay: Bool {
        return isConnected && audioEngine.isRunning
    }
    public func prepareToPlay() throws {
        if !isConnected {
            try connect()
        }
        if !audioEngine.isRunning {
            try audioEngine.start()
        }
        sequencer.preroll()
    }
    public func playStopToggle(){
        guard isPlaying else {
            try? play()
            return
        }
        stop()
    }
    
    public var isPlaying: Bool {
        return sequencer.isPlaying
    }
    public func stop(){
        guard transportState != .stopped else {
            return
        }
        sequencer.stop()
        for stemPlayer in activeStemPlayers {
            stemPlayer.stop()
        }
        sequencer.setTime(MusicTimeStamp(exactly: 0.0)!)
        transportStateInput.send(value: .stopped)
    }
    public func pause(){
        stop()
    }
    public func play() throws {
        if !isPreparedToPlay {
            try prepareToPlay()
        }
        sequencer.play()
        transportStateInput.send(value: .playing)
    }
}



public protocol AudioSequencerObserver /*: AudioTransportObserver*/ {
    func audioDeckObserver(_ audioDeckState: AudioSequencer.State, deck: AudioSequencer)
}


// MARK: SETTINGS
extension AudioSequencer: AudioSequencerProtocol {
    public func set(property: AudioSequencer.SettableProperty){
        switch property {
        case .FXSend(let volume): self.fxSend = volume
        case .outputVolume(let volume): self.volume = volume
        }
    }
    public func set(properties: [AudioSequencer.SettableProperty]){
        for property in properties {
            set(property: property)
        }
    }
    public func set(settings: Settings){
        self.set(properties: settings.properties)
    }
    /// Volume for mixer to fx send.
    var fxSend: Volume {
        get { return self.stemFXMixer.outputVolume }
        set { self.stemFXMixer.outputVolume = newValue }
    }
    /// Volume for mixer to main outputs.
    var volume: Volume {
        get { return self.outputMixer.outputVolume }
        set { self.outputMixer.outputVolume = newValue }
    }
    
    /// Controls the master volume for the sequencer. Should not be altered by cartridges. Put in place to allow crossfades between tracks.
    public var masterVolume: Volume {
        get {
            return mainMaster.outputVolume
        } set (newMasterVolume){
            mainMaster.outputVolume = newMasterVolume
            fxMaster.outputVolume = newMasterVolume
        }
    }
}

// MARK: CALCULATED VARS
extension AudioSequencer {
    private var engine: AVAudioEngine {
        return audioEngine.engine
    }
    
    internal static func activeStemPlayers(
        from allStemPlayers: [StemPlayer]
    ) -> [StemPlayer] {
        var activeStemPlayers: [StemPlayer] = []
        for stemPlayer in allStemPlayers {
            if stemPlayer.audioTrackState == .cued {
                activeStemPlayers.append(stemPlayer)
            }
        }
        return activeStemPlayers
    }
    
    // SETTING STATE TO READY SHOULD BE A FUNCTION WITH SOME VERIFICATION??
    public var sequencerState: AudioSequencer.State {
        return sequencerStateProperty.value
    }
    
    public var transportState: AudioTransportState {
        return audioTransportState.value
    }
    public var settings: Settings {
        return Settings(fxSend: self.fxSend, volume: self.volume)
    }
}


// MARK: HELPER METHODS
extension AudioSequencer {
    internal static func stemPlayers(
        from trackCount: Int,
        audioEngine: AudioEngineProtocol,
        outputMixer: AVAudioMixerNode,
        fxMixer: AVAudioMixerNode
    ) -> [StemPlayer] {
        
        var stemPlayers: [StemPlayer] = []
        for i in 0..<trackCount {
            let outputConnection = AVAudioConnectionPoint(
                node: outputMixer,
                bus: i
            )
            let fxConnection = AVAudioConnectionPoint(
                node: fxMixer,
                bus: i
            )
            let stemPlayer = StemPlayer(
                audioEngine: audioEngine,
                outputConnectionPoints: [outputConnection],
                fxConnectionPoints: [fxConnection],
                stemIndex: i
            )
                
            stemPlayers.append(stemPlayer)
        }
        return stemPlayers
    }
}






































