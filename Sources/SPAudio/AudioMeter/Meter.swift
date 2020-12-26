//
//  Meter.swift
//  InputMeter
//
//  Created by William Piotrowski on 7/2/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import UIKit
import AVFoundation
import AVKit
import ReactiveSwift

public class AudioMeter {
    
    // Test that intensity is correctly reset?
    /// A static property to define the default meter intensity. Should be set to this on init and reset.
    private static let defaultIntensity: Intensity = 0
    
    /// Default min dB reading. This should be used on init and reset. This affects the initial dynamic range of meter. Used to calculate both decibel reading and then volume ratio.
    internal static let defaultMinDb: Decibel = -60.0
    
    
    private static let defaultScale: IntensityMultipler = 1
    
    // Current design is that the meter is always held and the node is changed. Should the meter be dropped and a new one initialized for new taps?
    /// The audio node that is being tapped.
    private var node: AVAudioNode?
    
    private let meter = DurationMeter()
    private let meterMinimum = MeterMinimum()
    private let meterMaximum = MeterMaximum()
    private let audioEngine: AudioEngineProtocol
    
    /// Multiplier used to increase dynamic range.
    private var scale: IntensityMultipler
    
    
    private var didChange: (MeterReading) -> Void = { (meterReading)  in }
    public var speechTrigger: (_ word: String) -> Void = { arg in } {
        didSet {
            speechRecognition.triggerCallback = speechTrigger
        }
    }
//    public var intensityChange: ((Float) -> Void)?
    
    // MAY BE ABLE TO MAKE THIS COMPUTED?
    /// The average reading of quietest readings based on the MeterMinumum struct.
    private var averageMinimumDecibel: Decibel
    
    //internal var running = false
    var state: State = .off
    
    public let speechRecognition = SpeechRecognition()
    
    
    private let intensitySignalInput: Signal<Intensity, Never>.Observer
    public let intensityProperty: ReactiveSwift.Property<Intensity>
    
    public init(audioEngine: AudioEngineProtocol){
        
        let initialIntensity = AudioMeter.defaultIntensity
        
        let intensityPipe = Signal<Intensity, Never>.pipe()
        let intensityProperty = ReactiveSwift.Property(
            initial: initialIntensity,
            then: intensityPipe.output
        )
        
        self.averageMinimumDecibel = AudioMeter.defaultMinDb
        self.audioEngine = audioEngine
        self.intensitySignalInput = intensityPipe.input
        self.intensityProperty = intensityProperty
        self.scale = AudioMeter.defaultScale
        //self.changeSlowSpeed(ratio: self.slowSpeed)
        //meter.slowSpeedSeconds = 7
        meter.speed = 2.5
    }
    
    
    
}

// MARK: LISTENER UPDATE
extension AudioMeter {
    //Maybe store entire history of meter (with some limit?) so that can calculate lowest level in last five minutes, etc. Both dB and meter level
    private func update(buffer: AVAudioPCMBuffer, time: AVAudioTime){
        //Is there a way to ensure buffer? to create a new array to make buffer time 100%? Seems like it would change the meter if buffer frame length changes
        /*
        guard let channelData = buffer.floatChannelData else {
            return
        }
        */
        guard
            let bufferReading = try? BufferReading(buffer: buffer),
            let format = format
            else { return }
        
        self.speechRecognition.append(buffer: buffer)
        
        let bufferDecibelReading = bufferReading.decibel
        let bufferDecibelRatio = decibelRatio(from: bufferDecibelReading)
        
        //better place to calculate only on init and change?
        let bufferDuration = Second(
            format.sampleRate) / Float(buffer.frameLength
        )
        
        meter.set(singleReadingDuration: bufferDuration)
        meter.append(decibelRatio: bufferDecibelRatio)
        
        meterMinimum.append(decibelReading: bufferDecibelReading)
        
        if meterMinimum.average != 0 {
            averageMinimumDecibel = meterMinimum.average
        }
        
        let intensity: Intensity = meter.average * scale
        
        meterMaximum.append(intensity: intensity)
        
        self.scale = AudioMeter.scale(maximumRatio: meterMaximum.average)
        
//        self.value = fastLevel
        self.intensitySignalInput.send(value: intensity)
        
    }
}

// MARK: PUBLIC METHODS
extension AudioMeter {
    public var isRunning: Bool {
        switch state {
        case .off: return false
        case .running: return true
        }
    }
    public func attach(node: AVAudioNode){
        if(isRunning){
            stop()
            self.node = node;
            try? start()
        } else {
            self.node = node;
        }
    }
    
    public func start() throws {
        guard let node = node
            else { throw AudioMeterError.couldNotStartNoNode }
        guard !isRunning
            else { throw AudioMeterError.couldNotStartAlreadyRunning }
        if !audioEngine.isRunning {
            try audioEngine.start()
        }
        //if(node != nil && running == false){
            node.installTap(onBus: 0, bufferSize: 1024, format: self.format) { (buffer, time) in
                self.update(buffer: buffer, time: time)
            }
            
            speechRecognition.start()
            
        state = .running
        //}
    }
    public func stop(){
        guard isRunning
        else { return }
        
        // HAS CREATED AN ERROR WITHOUT ABOVE GUARD
        node?.removeTap(onBus: 0)
        
        // HAS CREATED AN ERROR WITHOUT ABOVE GUARD
        speechRecognition.stop()
        audioEngine.stopIfNotRunning()
        reset()
        
        state = .off
        //Occasionally locks up UI when turned on and off
    }
    /*
    func toggle() -> Bool{
        print("TOGGLING")
        if(isRunning){
            stop()
        } else {
            try? start()
        }
        return isRunning
    }
 */
    public func reset(){
        self.intensitySignalInput.send(value: AudioMeter.defaultIntensity)
        meterMaximum.reset()
        meterMinimum.reset()
        meter.reset()
        averageMinimumDecibel = AudioMeter.defaultMinDb
    }
    
    // Verify performance regarding escaping!
    public func setCallback(callback: @escaping (MeterReading) -> Void){
        self.didChange = callback
    }
    
    
    public func set(property: AudioMeter.AudioMeterProperty){
        switch property {
        case .fastSpeed(let ratio): changeFastSpeed(ratio: ratio)
        //case .slowSpeed(let ratio): changeSlowSpeed(ratio: ratio)
        }
    }
    
    public func set(properties: [AudioMeter.AudioMeterProperty]){
        for property in properties {
            set(property: property)
        }
    }
}


// MARK: TIMING
extension AudioMeter {
    private static let fastTimeRatio = MeterTimeRatio(
        floor: 0.3,
        multiplier: 9.5
    )
    
    private func changeFastSpeed(ratio: Float){
        let filteredSpeed = AudioMeter.filter(number: ratio)
        let seconds = AudioMeter.fastTimeRatio.seconds(fromRatio: filteredSpeed)
        // better way to do this in ratio??
        let finalSeconds = (seconds > 2.5) ? 2.5 : seconds
        meter.speed = finalSeconds
    }
    
    
    /// The duration of the meter as a ratio of 0 to 1
    public var meterSpeedRatio: Float {
        return AudioMeter.fastTimeRatio.ratio(fromSeconds: meter.speed)
    }
}

// MARK: CALCULATIONS
extension AudioMeter {
    /// Calculates the scale to multiply raw level ratios by to increase dynamic range. Returns a number that can be used to multiply the Decibel ratio by to get a more full range of dynamics.
    static func scale(
        maximumRatio: Intensity,
        limit: Float? = 10
    ) -> IntensityMultipler {
        let limit = limit ?? 10
        let scale = 1 / maximumRatio
        return (scale > limit) ? limit : scale
    }
    
    /// convert decibel readings to a ratio of 0 to 1
    private func decibelRatio(
        from decibel: Decibel
    ) -> DecibelRatio {
        return AudioMeter.decibelRatio(
            from: decibel,
            minimumDB: averageMinimumDecibel
        )
    }
    
    /// convert decibel readings to a ratio of 0 to 1
    static func decibelRatio (
        from decibel: Decibel,
        minimumDB: Decibel
    ) -> DecibelRatio {
        //Convert decibel to scale of 1
        guard decibel.isFinite
            else { return 0.0 }
        //Possibly set alt min in case there is no average
        
        // Calculate before switch and use that value to determine?
        switch decibel {
        case _ where decibel < minimumDB: return 0
        case _ where decibel >= 1.0: return 1.0
        default: return (abs(minimumDB) - abs(decibel)) / abs(minimumDB)
        }
        
    }
    
    /// Ensures that the number is less than or equal to 1 and greater than or equal to 0.
    public static func filter(
        number: Float,
        max: Float? = nil,
        min: Float? = nil
    ) -> Float {
        let max = max ?? 1
        let min = min ?? 0
        
        switch number {
        case _ where number < min: return min
        case _ where number > max: return max
        default: return number
        }
    }
}

// MARK: DYANAMIC VARS
extension AudioMeter {
    private var format: AVAudioFormat? {
        return node?.outputFormat(forBus: 0)
    }
}


