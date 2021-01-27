//
//  AudioEngine.swift
//  RPG Music
//
//  Created by William Piotrowski on 3/9/19.
//  Copyright © 2019 William Piotrowski. All rights reserved.
//

import SPCommon
import AVFoundation
//import AudioKit
import MediaPlayer
import WPNowPlayable
import ReactiveSwift

public protocol AudioEngineControllerProtocol {
    func stop()
    var isRunning: Bool { get }
}




public protocol PlaybackBrainProtocol: class {
    func play()
    func stop()
    func playStopToggle()
    func pause()
    func cuePrevious() throws
    func cueNext() throws
}

/// A Void element that can be a placeholder for more useful information in the future. This is sent as a value when the audio engine periodically updates every 0.2 (currently) seconds.
public typealias AudioEnginePeriodicUpdate = Void

public class AudioEngine /*: Observable2 */{
    //var observations: [ObjectIdentifier : Observer] = [:]
//    public var observations2: [ObjectIdentifier : Observer2] = [:]
    
    
    public let engine: AVAudioEngine
//    private let akEngine: AudioKit.AudioEngine
    
//    let outputMixer: Mixer
    public let avMixer: AVAudioMixerNode
    //weak var transport: PlaybackBrain?
    public weak var transport: PlaybackBrainProtocol?
//    let avMixerAKNode: Node
    public let session = AudioSession()
    
    
    // ABstract and hold in array so this AudioEngine is not scoped to Scorepio project?
    public weak var playbackEngine: AudioPlayback?
    public weak var inputEngine: InputAudioEngine?
    
    ///
    //public let periodicUpdateSignal: Signal<AudioEnginePeriodicUpdate, Never>
    private let periodicUpdateSignalInput: Signal<AudioEnginePeriodicUpdate, Never>.Observer
    public let periodicUpdateSignalProducer: SignalProducer<AudioEnginePeriodicUpdate, Never>
    
    private var timer: Timer?
    
//    private var akPeriodicFunction: AKPeriodicFunction
    
    
    public init(){
        //self.iOSNowPlayable = IOSNowPlayableBehavior()
        
        let periodicUpdatePipe = Signal<AudioEnginePeriodicUpdate, Never>.pipe()
        let periodicUpdateSignalProducer = SignalProducer(
            periodicUpdatePipe.output
        )
        
        
//        let outputMixer = Mixer()
//        let akEngine = AudioKit.AudioEngine()
//        akEngine.output = outputMixer
        let engine = AVAudioEngine()
        
        let avMixer = AVAudioMixerNode()
        //self.periodicUpdateSignal = periodicUpdatePipe.output
        self.periodicUpdateSignalInput = periodicUpdatePipe.input
        self.periodicUpdateSignalProducer = periodicUpdateSignalProducer
//        self.akEngine = akEngine
//        self.outputMixer = outputMixer
        self.avMixer = avMixer
//        self.avMixerAKNode = Node(avAudioNode: avMixer)
        self.engine = engine
        
        engine.attach(avMixer)
        engine.connect(avMixer, to: engine.mainMixerNode, format: nil)
        
//        self.akPeriodicFunction = AKPeriodicFunction(every: 1, handler: {})
//        self.akPeriodicFunction = AKPeriodicFunction(
//            every: 1,
//            handler: periodicUpdateHandler
//        )
        //connect()
        
    }
    
//    private func periodicUpdateHandler(){
//        let observation = Observation2.audioEngine
//        //let observation = Observation.audioEngine
//        sendToObservers2(observation)
//        //sendToObservers(observation)
//    }
//
    
    private func periodicUpdateHandler(_ timer: Timer){
        self.periodicUpdateSignalInput.send(value: ())
//        let observation = Observation2.audioEngine
        //let observation = Observation.audioEngine
//        sendToObservers2(observation)
        //sendToObservers(observation)
        
//        print("TIMER UPDATE!")
        
        if !self.isRunning {
            timer.invalidate()
        }
    }
    
    public var isRunning: Bool {
        return engine.isRunning
    }
    func prepare(){
        engine.prepare()
    }
    
    deinit {
        print("STOPPING AUDIO ENGINE!!!")
        stop()
        engine.stop()
//        akEngine.stop()
//        do {
//            try AudioKit.stop()
//        } catch {
//            print("error stopping audio kit")
//        }
        
    }
    
    public func start() throws {
        guard !isRunning
            else {
                return
                // COULD THROW ERROR
            }
        //print("START AUDIO ENGINE!!!!")
        try startAudioKit()
        
        // TRY start(withPeriodicFunctions functions: AKPeriodicFunction...)
        session.start()
        
        
//        let timer = Timer(
//            timeInterval: 0.2,
//            repeats: true,
//            block: self.periodicUpdateHandler
//        )
//        self.timer = timer
        Timer.scheduledTimer(
            withTimeInterval: 0.2,
            repeats: true,
            block: self.periodicUpdateHandler
        )
        
        
        //engine.start()
        //configureAudioSession()
               /*
               engine.prepare()
               do {
                   try engine.start()
               } catch let error {
                   print(error.localizedDescription)
               }
        */
    }
 
    func pause(){
        engine.pause()
    }
    public func stop(){
        //engine.stop()
        inputEngine?.stop()
        playbackEngine?.stop()
        engine.stop()
//        akEngine.stop()
        timer?.invalidate()
        timer = nil
//        do {
//            try AudioKit.stop()
//        } catch {
//            print("error stopping audio kit")
//        }
        session.stop()
        disconnect()
        engine.reset()
        print("ENGINE STOPPED!!!")
    }
    public func stopIfNotRunning(){
        if !isChildEngineRunning {
            stop()
        }
    }
    private var isChildEngineRunning: Bool {
        if
            let inputEngine = inputEngine,
            inputEngine.isRunning
        { return true }
        if
            let playbackEngine = playbackEngine,
            playbackEngine.isRunning
        { return true }
        return false
    }
    private func startAudioKit() throws {
        /*
        let temp = AKPeriodicFunction(frequency: 1, handler: {
            print("HELLO")
        })
*/

//        akPeriodicFunction.stop()
//        akPeriodicFunction.restart()
        connect()
//        AudioKit.output = outputMixer
//        try akEngine.start()
        try engine.start()
//        try AudioKit.start(withPeriodicFunctions: akPeriodicFunction)
//        akPeriodicFunction.start()
        //try AudioKit.start()
    }
    private func connect(){
//        outputMixer.addInput(avMixerAKNode)
//        outputMixer.connect(input: avMixerAKNode)
    }
    
    private func disconnect(){
//        outputMixer.removeInput(avMixerAKNode)
//        avMixerAKNode.disconnectOutput()
        //avMixer.disconnectOutput()
        //outputMixer.disconnectInput()
    }
    private func handleCommand(command: NowPlayableCommand, event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard let playbackEngine = transport else {
            return .commandFailed
        }
        let transport = playbackEngine
        /*
        guard let transport = playbackEngine.transport else {
            return .noActionableNowPlayingItem
        }
         */
        switch command {
        case .play: transport.play()
        case .stop: transport.stop()
        case .togglePausePlay: transport.playStopToggle()
        case .pause: transport.pause()
        case .nextTrack:
            do {
                try playbackEngine.cueNext()
            } catch {
                print(error)
                return .commandFailed
            }
        case .previousTrack:
            do {
                try playbackEngine.cuePrevious()
            } catch {
                print(error)
                return .commandFailed
            }
        default: return .commandFailed
        }
        return .success
    }
    
    private func handleInterrupt(with interruption: NowPlayableInterruption) {
    }
    
    /*
    var inputs: [AudioDevice]? {
        print("INPUT NODE: \(engine.inputNode)")
        print("INPUT FORMAT: \(engine.inputNode.inputFormat(forBus: 0))")
        print("AK INPUTS: \(AudioKit.inputDevices)")
        print("AK INPUT: \(AudioKit.inputDevice)")
        guard let akInputs = AudioKit.inputDevices
            else { return nil }
        var inputs = [AudioDevice]()
        for akInput in akInputs {
            inputs.append(AudioDevice(akDevice: akInput))
        }
        
        
        
        return inputs
    }
 */
    public var inputDevice: AudioInputDevice? {
        do {
            return try AudioInputDevice(inputNode: engine.inputNode, session: session)
        } catch {
            print("COULD NOT CREATE INPUT DEVICE: \(error)")
            return nil
        }
    }
    
    
}




public struct AudioInputDevice {
    private let inputNode: AVAudioInputNode
    let bus: Int
    let portDescription: AudioPortDescription?
    
    init (
        inputNode: AVAudioInputNode,
        session: AudioSession,
        bus: Int? = nil
    ) throws {
        let bus = bus ?? 0
        
        // NOT SURE THIS IS A GREAT IDEA??
        //guard
        let portDescription = session.preferredInput
        //    else { throw AudioInputDeviceError.noPreferredInput }
        
        guard session.recordPermission.isRecordingPermitted
            else { throw AudioInputDeviceError.micPermissionNotGranted }
        
        let format = inputNode.inputFormat(forBus: bus)
        guard format.channelCount > 0
            else { throw AudioInputDeviceError.zeroChannelCount }
        guard format.sampleRate > 0
            else { throw AudioInputDeviceError.zeroSampleRate }
        
        self.portDescription = portDescription
        self.inputNode = inputNode
        self.bus = bus
    }
    
    var numberOfInputs: Int {
        return inputNode.numberOfInputs
    }
    var numberOfOutputs: Int {
        return inputNode.numberOfOutputs
    }
    var name: String {
        return portDescription?.name ?? "Unknown"
    }
    public var avNode: AVAudioNode {
        return inputNode
    }
    
    enum AudioInputDeviceError: ScorepioError {
        case zeroChannelCount
        case zeroSampleRate
        case noPreferredInput
        case micPermissionNotGranted
        
        var message: String {
            switch self {
            case .zeroChannelCount: return "Could not instantiate AudioInputDevice because channel count was not greater than 0."
            case .zeroSampleRate: return "Could not instantiate AudioInputDevice because sample rate was not greater than 0."
            case .noPreferredInput: return "Could not instantiate AudioInputDevice because session does not have a preferred input."
            case .micPermissionNotGranted: return "Could not instantiate AudioInputDevice because mic permission was not granted."
            }
        }
    }
}
