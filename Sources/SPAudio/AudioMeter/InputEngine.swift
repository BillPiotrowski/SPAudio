//
//  InputEngine.swift
//  RPG Music
//
//  Created by William Piotrowski on 3/9/19.
//  Copyright © 2019 William Piotrowski. All rights reserved.
//
/*
import SPCommon
import WPAudio
import InputMeter

class InputEngine: Observable {
    private let inputAudioEngine: InputAudioEngine
    private let trailingMeter: TrailingMeter
    private var input: Input = .none {
        didSet {
            let observation = Observation.inputEngine(input: self.input.inputOption, isRunning: self.isRunning)
            sendToObservers(observation)
        }
    }
    private (set) var isRunning: Bool = false {
        didSet {
            let observation = Observation.inputEngine(input: self.input.inputOption, isRunning: self.isRunning)
            sendToObservers(observation)
        }
    }
    private var intensity: Float = 0 {
        didSet {
            //trailingMeter.append(value: intensity)
            meterReading = MeterReading(
                intensityFast: intensity,
                intensitySlow: trailingMeter.average
            )
        }
    }
    
    var observations: [ObjectIdentifier : Observer] = [:]
    
    private (set) var meterReading: MeterReading? {
        didSet {
            guard let meterReading = meterReading
                else { return }
            let observation = Observation.meter(reading: meterReading)
            sendToObservers(observation)
        }
    }
    
    var speechTrigger: (_ word: String) -> Void = { arg in } {
        didSet {
            meter.speechTrigger = speechTrigger
        }
    }
    
    init(
        inputAudioEngine: InputAudioEngine
    ){
        self.inputAudioEngine = inputAudioEngine
        self.trailingMeter = TrailingMeter(
            duration: InputEngine.defaultTrailingSpeed
        )
        inputAudioEngine.recordedDialogMixer.volume = 0.7
        meter.intensityChange = self.meterIntensityChangeHandler
    }
}

// MARK: INPUT SELECTION
extension InputEngine {
    func set(inputOption: InputOption) throws {
        let wasRunning = isRunning
        input.stop()
        switch inputOption {
        case .audioPlayer: useRecording()
        case .inputDevice: try useMic()
        case .manual: useManual()
        case .random: useRandom()
        }
        if wasRunning {
            try start()
        }
    }
    private func useManual() {
        let meter = ManualMeter(
            audioEngine: self.audioEngine,
            trailingMeter: self.trailingMeter,
            callback: { val in
                self.intensity = val
            },
            value: self.intensity
        )
        meter.start()
        input = .manual(meter: meter)
    }
    private func useMic() throws {
        guard let inputDevice = audioEngine.inputDevice else {
            throw InputEngineError.noDeviceInputs
        }
        meter.attach(node: inputDevice.avNode)
        input = .microphone(meter: meter, microphone: inputDevice)
    }
    private func useRandom(){
        let randomGenerator = RandomGenerator(
            audioEngine: audioEngine,
            callback: randomGeneratorCallback
        )
        input = .random(
            generator: randomGenerator
        )
    }
    
    private func useRecording(){
        meter.attach(node: recordedDialogPlayer.node)
        input = .recording(
            meter: meter,
            audioPlayer: recordedDialogPlayer
        )
    }
}

// MARK: RANDOM HANDLER
extension InputEngine {
    private func randomGeneratorCallback(value: Float){
        switch input {
        case .random:
            trailingMeter.append(value: value)
            meterReading = MeterReading(
                intensityFast: value,
                intensitySlow: trailingMeter.average
            )
            //print("RANDOM GENERATOR: \(value)")
        default: break
        }
    }
}

// MARK: AUDIO METER HANDLER
extension InputEngine {
    private func meterIntensityChangeHandler(
        value: Float
    ){
        switch input {
        case .microphone, .recording:
            trailingMeter.append(value: value)
            self.meterReading = MeterReading(intensityFast: value, intensitySlow: trailingMeter.average)
        default: break
        }
    }
}

// MARK: MANUAL HANDLER
extension InputEngine {
    private func manualHandler(reading: Float){
        guard case .manual(let meter) = input
            else { return }
        meter.set(value: reading)
        //intensity = AudioMeter.filter(number: reading)
    }
}


// MARK: START / STOP LISTENING
extension InputEngine {
    
    func start() throws {
        print("START LISTENING: \(input)")
        switch input {
        case .microphone, .recording:
            try meter.start()
        case .random(let generator):
            generator.start()
        case .manual: break
        case .none: break
        }
        self.isRunning = checkIsRunning
    }
    
    func stop(){
        meter.stop()
        audioEngine.stopIfNotRunning()
        self.isRunning = checkIsRunning
        
    }
    func startStopToggle() throws {
        if isRunning {
            stop()
        } else {
            try start()
        }
    }
    
    private var checkIsRunning: Bool {
        switch input {
        case .microphone, .recording:
            return meter.isRunning
        case .random(let generator):
            return generator.isRunning
        case .manual: return false
        case .none: return false
        }
    }
}

// MARK: PUBLIC FUNCS / VARS
extension InputEngine {
    var recordedDialogVolume: Float {
        get {
            return inputAudioEngine.recordedDialogMixer.volume
            // better to use outputVolume ???
            //return recordedDialogMixer.outputVolume
        } set (newMasterVolume){
            inputAudioEngine.recordedDialogMixer.volume = newMasterVolume
        }
    }
    func set(property: InputEngine.Property){
        switch property {
        case .recordedDialogVolume(let volume):
            inputAudioEngine.recordedDialogMixer.volume = volume
        case .fastSpeed(let ratio):
            meter.set(property: .fastSpeed(ratio: ratio))
        case .slowSpeed(let ratio):
            let filteredSpeed = AudioMeter.filter(number: ratio)
            let seconds = InputEngine.trailingMeterTimeRatio.seconds(fromRatio: filteredSpeed)
            trailingMeter.set(property: .duration(seconds: Double(seconds)))
        case .manual(let reading):
            manualHandler(reading: reading)
        }
    }
    func set(properties: [InputEngine.Property]){
        for property in properties {
            set(property: property)
        }
    }
    
    /// Duration of the audio meter as a ratio from 0-1
    var audioMeterSpeedRatio: Float {
        return meter.meterSpeedRatio
    }
    /// Length of trailing meter in ratio from 0 to 1.
    var trailingSpeedRatio: Float {
        return InputEngine.trailingMeterTimeRatio.ratio(fromSeconds: Float(trailingSpeed))
    }
    /// The speed of the trailing meter in seconds.
    var trailingSpeed: Double {
        trailingMeter.duration
    }
    var speechRecognition: SpeechRecognition {
        return meter.speechRecognition
    }
}


// MARK: DEFINITIONS
extension InputEngine {
    
    var inputOptions: [InputOption] {
        return [.inputDevice, .audioPlayer, .random, .manual]
    }
    
    private enum Input {
        case none
        case random(generator: RandomGenerator)
        case microphone(meter: AudioMeter, microphone: AudioInputDevice)
        case recording(meter: AudioMeter, audioPlayer: AudioPlayer)
        case manual(meter: ManualMeter)
        
        func stop(){
            switch self {
            case .random(let generator):
                //trailingMeter.stop()
                generator.stop()
            case .microphone(let meter, _):
                meter.stop()
            case .recording(let meter, let audioPlayer):
                audioPlayer.stop()
                meter.stop()
            case .manual(let meter):
                meter.stop()
            case .none: break
            }
        }
        
        var inputOption: InputOption? {
            switch self {
            case .random: return .random
            case .microphone: return .inputDevice
            case .recording: return .audioPlayer
            case .manual: return .manual
            default: return nil
            }
        }
        
    }
    
    enum InputOption: Int {
        case inputDevice = 0
        case audioPlayer = 1
        case manual = 2
        case random = 3
    
        var name: String {
            switch self {
            case .inputDevice: return "Device Input"
            case .audioPlayer: return "Audio Player"
            case .manual: return "Manual"
            case .random: return "Random"
            }
        }
    }
    
    enum Property {
        case recordedDialogVolume(volume: Float)
        case fastSpeed(ratio: Float)
        case slowSpeed(ratio: Float)
        case manual(reading: Float)
    }
    
    enum InputEngineError: ScorepioError {
        case noDeviceInputs
        
        var message: String {
            switch self {
            case .noDeviceInputs: return "There are no device inputs. Please check to make sure the microphone is allowed for this app in iPhone settings."
            }
        }
    }
    
    /// Sets a minimum duration and a scalable duration in seconds. Default is minimum of 0.75 and a maximum of 19.5 (scaled) + 0.75.
    private static let trailingMeterTimeRatio = MeterTimeRatio(
        floor: 0.75,
        multiplier: 19.5
    )
    
    /// Default trailing meter speed of 7 seconds.
    static let defaultTrailingSpeed: Double = 7
}

// MARK: CALCULATED VARS
extension InputEngine {
    var audioEngine: AudioEngine {
        return inputAudioEngine.audioEngine
    }
    var recordedDialogPlayer: AudioPlayer {
        return inputAudioEngine.recordedDialogPlayer
    }
    private var meter: AudioMeter {
        return inputAudioEngine.meter
    }
    var inputOption: InputOption? {
        return input.inputOption
    }
}


*/
