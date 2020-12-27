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

/*
struct MidiDuration {
    private let samples: Int
    private let sampleRate: Double
    private let tempo: Double
    
    init(samples: Int, sampleRate: Double, tempo: Double) {
        self.samples = samples
        self.sampleRate = sampleRate
        self.tempo = tempo
    }
}
 */
/*
protocol MidiDuration {
    
    init(samples: Int, sampleRate: Double, tempo: Double)
}
extension MidiDuration {
    /*
    var akDuration: AKDuration {
        return AKDuration(samples: samples, sampleRate: sampleRate, tempo: tempo)
    }
 */
}
*/
/*
public protocol MidiNoteData {
    
}
extension AKMIDINoteData: MidiNoteData {
    
}

protocol MidiSequencer {
    func preroll()
    var isPlaying: Bool { get }
    var trackCount: Int { get }
    func stop()
    func play()
    func setTime(_ timestamp: MusicTimeStamp)
    func loadMIDIFile(fromURL: URL)
    var midiTracks: [MidiTrack] { get }
    //func newTrack()
    //func newTrack(_ name: String?) -> AKMusicTrack?
    func createNewTrack() -> MidiTrack?
    var length: AKDuration { get }
    func clearRange(start: AKDuration, duration: AKDuration)
    func setTempo(_: Double)
    var currentPosition: AKDuration { get }
}
protocol MidiTrack {
    func setMIDIOutput(_ endpointRef: MIDIEndpointRef)
    func setLoopInfo(_ duration: AKDuration, numberOfLoops: Int)
    var length: Double { get }
    func setLength(_ duration: AKDuration)
    func add(midiNoteData: AKMIDINoteData)
    func addNote(
        noteNumber: UInt8,
        velocity: UInt8,
        position: MidiDuration,
        duration: MidiDuration,
        channel: UInt8
        /*
        noteNumber: MIDINoteNumber,
        velocity: MIDIVelocity,
        position: AKDuration,
        duration: AKDuration,
        channel: MIDIChannel
 */
    )
}
extension AKAppleSequencer: MidiSequencer {
    func createNewTrack() -> MidiTrack? {
        return self.newTrack()
    }
    
    
    var midiTracks: [MidiTrack] {
        return tracks
    }
}
extension AKMusicTrack: MidiTrack {
    func addNote(
        noteNumber: UInt8,
        velocity: UInt8,
        position: MidiDuration,
        duration: MidiDuration,
        channel: UInt8
    ) {
        //let positionDuration = AKDuration(
        self.add(
            noteNumber: noteNumber,
            velocity: velocity,
            position: position.akDuration,
            duration: duration.akDuration,
            channel: channel
        )
    }
    
    
}
 */
public class AudioSequencer: Observable2 {
    private let mainMaster = AVAudioMixerNode()
    private let fxMaster = AVAudioMixerNode()
    private let outputMixer = AVAudioMixerNode()
    private let stemMixer: AVAudioMixerNode
    private let fxMixer: AVAudioMixerNode
    private let playerConnectionPoints: [AVAudioConnectionPoint]
    private let fxConnectionPoints: [AVAudioConnectionPoint]
    private let audioEngine: AudioEngineProtocol
    private let tracks: Int = 9
    private let privateStemPlayers: [StemPlayer]
    private var privateSequencer: AppleSequencer?
    //private var privateSequencer: MidiSequencer?
    
    public private(set) var isConnected: Bool = false
    
    
    private let (transportStateOutput, transportStateInput): (Signal<AudioTransportState, Never>, Signal<AudioTransportState, Never>.Observer)
    public let audioTransportState: Property<AudioTransportState>
    
    public let synth: Synth

    //var sequenceCartridge: SequenceCartridge?
    //internal var observations: [ObjectIdentifier : Observer4] = [:]
    public var observations2: [ObjectIdentifier : Observer2] = [:]
    
    public var sequencerState: AudioSequencer.State = .empty {
        didSet {
            let observation = Observation2.audioSequencer(sequencerState: sequencerState, deck: self)
            //print("SEND audio SEQ")
            sendToObservers2(observation)
        }
    }
    
    // REMOVE THE VARS FROM CLASS THAT ARE STORED IN STATE!!!!
    public var transportState: AudioTransportState = .stopped {
        didSet {
            guard transportState != oldValue
            else {
                print("duplicate transport command")
                return
            }
            
//            let observation = Observation2.audioTransport(transportState: transportState)
            transportStateInput.send(value: transportState)
            //print("SEND TRANSPORT")
//           sendToObservers2(observation)
        }
    }
    
    public init(
        audioEngine: AudioEngineProtocol,
        playerConnectionPoint: AVAudioConnectionPoint,
        fxConnectionPoint: AVAudioConnectionPoint
        //conductorTrackCallbackInstrument: AKMIDICallbackInstrument
    ){
        //self.conductorTrackCallbackInstrument = conductorTrackCallbackInstrument
        let stemMixer = AVAudioMixerNode()
        let fxMixer = AVAudioMixerNode()
        let synth = Synth()
        
        let signal = Signal<AudioTransportState, Never>.pipe()
        let property = Property(
            initial: AudioTransportState.stopped,
            then: signal.output
        )
        
        var stemPlayers: [StemPlayer] = []
        for i in 0..<tracks{
            let stemPlayer = StemPlayer(audioEngine: audioEngine, outputConnectionPoints: [AVAudioConnectionPoint(node: stemMixer, bus: i+tracks)], fxConnectionPoints: [AVAudioConnectionPoint(node: fxMixer, bus: i+tracks)])
            stemPlayers.append(stemPlayer)
        }
        
        self.synth = synth
        self.playerConnectionPoints = [playerConnectionPoint]
        self.fxConnectionPoints = [fxConnectionPoint]
        self.audioEngine = audioEngine
        self.transportStateInput = signal.input
        self.transportStateOutput = signal.output
        self.audioTransportState = property
        self.stemMixer = stemMixer
        self.fxMixer = fxMixer
        self.privateStemPlayers = stemPlayers
        
        attach()
        //synth.connect(to: audioEngine.outputMixer)
    }
}

// MARK:ATTACH ENGINE
extension AudioSequencer {
    func attach(){
        engine.attach(outputMixer)
        engine.attach(stemMixer)
        engine.attach(fxMixer)
        engine.attach(mainMaster)
        engine.attach(fxMaster)
        engine.attach(synth.avAudioNode)
        
    }
}

// MARK: RESET
extension AudioSequencer {
    public func reset() {
        if isConnected {
            disconnect()
        }
        //for i in 0..<privateSequencer.trackCount {
        //    privateSequencer.deleteTrack(trackIndex: i)
        //}
        
        self.privateSequencer = AppleSequencer()
        //self.sequenceCartridge = nil
        for stemPlayer in activeStemPlayers {
            stemPlayer.uncue()
        }
        set(properties: defaults)
        sequencerState = .empty
    }
    
}

// MARK: CONNECT
extension AudioSequencer {
    func connect() throws {
        print("START CONNECT SEQ")
        //synth.connect(to: audioEngine.outputMixer)
        //print("SEQ SYNTH CONNECT 1: \(synth.avAudioNode.isOutputConnected)")
        //outputMixer.connect(input: synth.avAudioNode, bus: 2, format: nil)
        
        
        
        
        engine.connect(synth.avAudioNode, to: outputMixer, fromBus: 0, toBus: 2, format: nil)
        
        
        
        
        
        //synth.avAudioNode.connect(input: outputMixer, bus: 2)
        //synth.avA
        //synth.avAudioNode.numberOfOutputs
        //synth.avAudioUnit?.connect(input: outputMixer, bus: 2, format: nil)
        //let tempMixer = Mixer()
        //tempMixer.addInput(synth)
        //print("SEQ SYNTH CONNECT 2: \(synth.avAudioNode.isOutputConnected)")
        //synth.connect(to: AVAudioConnectionPoint(node: outputMixer, bus: 2))
        // BETTER WAY TO DO THIS??? BACKUP DEFAULT SETTING???
        let audioFormat = stemPlayers[0].audioFormat ?? synth.avAudioNode.outputFormat(forBus: 0)
        
        
        
        
        //ORDER IS IMPORTANT. PUTTING STEMS AFTER MIXER WILL BREAK WITH PITCH AUDIO UNIT!!!!!
        for stemPlayer in activeStemPlayers {
            try stemPlayer.connect()
        }
        let fxOut = try AVAudioConnectionPoint.connectable(fxConnectionPoints)
        let outPoints = try AVAudioConnectionPoint.connectable(playerConnectionPoints)
        
        try engine.connect(from: fxMixer, to: fxMaster, fromBus: 0, toBus: 0, format: audioFormat)
        engine.connect(stemMixer, to: outputMixer, fromBus: 0, toBus: 0, format: audioFormat)
        engine.connect(outputMixer, to: mainMaster, fromBus: 0, toBus: 0, format: audioFormat)
        
        engine.connect(fxMaster, to: fxOut, fromBus: 0, format: audioFormat)
        engine.connect(mainMaster, to: outPoints, fromBus: 0, format: audioFormat)
        //AudioKit.connect(synth.outputNode, to: audioEngine.outputMixer.avAudioNode, format: audioFormat)
        isConnected = checkConnection()
        print("SEQ IS CONNECTED: \(isConnected)")
            print("END CONNECT SEQ")
    }
    public func disconnect(){
        if isPlaying {
            stop()
        }
        for stemPlayer in activeStemPlayers {
            stemPlayer.disconnect()
        }
        engine.disconnectNodeOutput(synth.avAudioNode)
        engine.disconnectNodeOutput(fxMixer)
        engine.disconnectNodeOutput(stemMixer)
        engine.disconnectNodeOutput(outputMixer)
        engine.disconnectNodeOutput(mainMaster)
        engine.disconnectNodeOutput(fxMaster)
        engine.disconnectNodeInput(outputMixer)
        //synth.avAudioNode.disconnect(input: outputMixer)
        //synth.disconnectOutput()
        isConnected = checkConnection()
    }
    
    
    //Maybe just make this a variable that is changed when connected / disconnected instead of checking manually?
    func checkConnection() -> Bool{
        guard fxMixer.isOutputConnected,
            stemMixer.isOutputConnected,
            outputMixer.isOutputConnected,
            fxMaster.isOutputConnected,
            mainMaster.isOutputConnected
            else {
                print("NOT CONNECTED")
                return false
                
        }
        for stemPlayer in activeStemPlayers {
            guard stemPlayer.isConnected else { return false }
        }
        return true
    }
}

// MARK: VOLUME
extension AudioSequencer {
    /// Controls the master volume for the sequencer. Should not be altered by cartridges. Put in place to allow crossfades between tracks.
    public var masterVolume: Float {
        get {
            return mainMaster.outputVolume
        } set (newMasterVolume){
            //print("master volume: \(newMasterVolume)")
            mainMaster.outputVolume = newMasterVolume
            fxMaster.outputVolume = newMasterVolume
        }
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
        sequencer?.preroll()
    }
    public func playStopToggle(){
        guard isPlaying else {
            play()
            return
        }
        stop()
    }
    
    public var isPlaying: Bool {
        return sequencer?.isPlaying ?? false
    }
    public func stop(){
        guard transportState != .stopped else {
            return
        }
        sequencer?.stop()
        for stemPlayer in activeStemPlayers {
            stemPlayer.stop()
        }
        sequencer?.setTime(MusicTimeStamp(exactly: 0.0)!)
        transportState = .stopped
        transportStateInput.send(value: .stopped)
    }
    public func pause(){
        // PAUSE PROBABLY DOESN'T WORK IN THIS SITUATION??? WOULD BE DELAY BEFORE NOTES ARE RETRIGGERED AND THEY WON't LINEUP AT NEXT MEASURE.
        stop()
    }
    public func play(){
        // DONT CHECK SO THAT PREROLL HAPPENS REGARDLESS
        //if !isPreparedToPlay {
        //print("PLAY ATTEMPT SEQ")
        
        do {
            if !isPreparedToPlay {
                try prepareToPlay()
            }
            sequencer?.play()
            //print("PLAYING: \(isPlaying)")
            transportState = .playing
            transportStateInput.send(value: .playing)
        } catch {
            //audioEngine.stopIfNotRunning()
        }
        /*
        do {
            try prepareToPlay()
        } catch {
            print(error)
        }
        //}
        if isPreparedToPlay {
            sequencer?.play()
            print("PLAYING: \(isPlaying)")
            transportState = .playing
        }
 */
    }
}



public protocol AudioSequencerObserver /*: AudioTransportObserver*/ {
    func audioDeckObserver(_ audioDeckState: AudioSequencer.State, deck: AudioSequencer)
}


public protocol AudioSequencerProtocol {
    var stemPlayers: [StemPlayer] { get }
    //var sequencer: MidiSequencer? { get }
    var sequencer: AppleSequencer? { get }
    var isPlaying: Bool { get }
    func set(property: AudioSequencer.SettableProperty)
    func set(properties: [AudioSequencer.SettableProperty])
    
    func addObserver2(_ observerClass: ObserverClass2)
    func removeObserver2(_ observerClass: ObserverClass2)
    
    func reset()
}

extension AudioSequencer: AudioSequencerProtocol {
    public enum SettableProperty {
        case FXSend(volume: Float)
        case outputVolume(volume: Float)
    }
    /*
       var sequencer: MidiSequencer? {
           return privateSequencer
       }
*/
       public var sequencer: AppleSequencer? {
           return privateSequencer
       }
    
    public var stemPlayers: [StemPlayer] {
        return privateStemPlayers
    }
    public func set(property: AudioSequencer.SettableProperty){
        switch property {
        case .FXSend(let volume): fxMixer.outputVolume = volume
        case .outputVolume(let volume): outputMixer.outputVolume = volume
        }
    }
    public func set(properties: [AudioSequencer.SettableProperty]){
        for property in properties {
            set(property: property)
        }
    }
}

// MARK: CALCULATED VARS
extension AudioSequencer {
    private var defaults: [AudioSequencer.SettableProperty] {
        return [.FXSend(volume: 1), .outputVolume(volume: 1)]
    }
    private var engine: AVAudioEngine {
        return audioEngine.engine
    }
    var activeStemPlayers: [StemPlayer] {
        var activeStemPlayers: [StemPlayer] = []
        for stemPlayer in stemPlayers {
            if stemPlayer.audioTrackState == .cued {
                activeStemPlayers.append(stemPlayer)
            }
        }
        return activeStemPlayers
    }
}


// MARK: DEFINITIONS
extension AudioSequencer {
    public enum State {
        case empty
        case ready
        case loading/*(cue: CueData)*/
        case cued/*(transport: AudioPlayerTransport/*, trackData: TrackData*/, tracks: [StemPlayer], sectionIndex: Int, cue: CueData)*/
        case error
    }
}







































