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

/// A meter tap on an audio node. Has an intensityProperty (Intensity) which is an ajusted metric of decibel loudness on a scale of 0 to 1 with 1 being the loudest. Audio node can be set and meter can be turned on and off.
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
    
    private let meter: DurationMeter
    private let meterMinimum = MeterMinimum()
    private let meterMaximum = MeterMaximum()
    private let audioEngine: AudioEngineProtocol
    
    /// Multiplier used to increase dynamic range.
    private var scale: IntensityMultipler
    
    public var speechTrigger: (_ word: String) -> Void = { arg in } {
        didSet {
            speechRecognition.triggerCallback = speechTrigger
        }
    }
    
    // MAY BE ABLE TO MAKE THIS COMPUTED?
    /// The average reading of quietest readings based on the MeterMinumum struct.
    internal private(set) var averageMinimumDecibel: Decibel
    
    var state: State = .off
    
    public let speechRecognition = SpeechRecognition()
    
    private let intensitySignalInput: Signal<Intensity, Never>.Observer
    public let intensityProperty: ReactiveSwift.Property<Intensity>
    
    
    /// Creates a meter tap on an audio node. Has an intensityProperty (Intensity) which is an ajusted metric of decibel loudness on a scale of 0 to 1 with 1 being the loudest.
    /// - Parameters:
    ///   - audioEngine: The audio engine that the audio node to be measured will exist on.
    ///   - speed: The speed of the meter in seconds. Meter measures intensity over a lagging period of time. If not set, default will be used. Default is 2.5 seconds.
    public init(
        audioEngine: AudioEngineProtocol,
        speed: Second? = nil
    ){
        
        let initialIntensity = AudioMeter.defaultIntensity
        
        let intensityPipe = Signal<Intensity, Never>.pipe()
        let intensityProperty = ReactiveSwift.Property(
            initial: initialIntensity,
            then: intensityPipe.output
        )
        
        let durationMeter = DurationMeter(speed: speed)
        
        self.meter = durationMeter
        self.averageMinimumDecibel = AudioMeter.defaultMinDb
        self.audioEngine = audioEngine
        self.intensitySignalInput = intensityPipe.input
        self.intensityProperty = intensityProperty
        self.scale = AudioMeter.defaultScale
    }
    
    
    
}

// MARK: LISTENER UPDATE
extension AudioMeter {
    //Maybe store entire history of meter (with some limit?) so that can calculate lowest level in last five minutes, etc. Both dB and meter level
    private func update(buffer: AVAudioPCMBuffer, time: AVAudioTime){
        //Is there a way to ensure buffer? to create a new array to make buffer time 100%? Seems like it would change the meter if buffer frame length changes
        
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
        
            node.installTap(
                onBus: 0,
                bufferSize: 1024,
                format: self.format
            ) { (buffer, time) in
                self.update(buffer: buffer, time: time)
            }
            
            speechRecognition.start()
            
        state = .running
        
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
    
    public func reset(){
        self.intensitySignalInput.send(value: AudioMeter.defaultIntensity)
        meterMaximum.reset()
        meterMinimum.reset()
        meter.reset()
        averageMinimumDecibel = AudioMeter.defaultMinDb
    }
    
    // CAN EVENTUALLY REMOVE THIS METHOD AND REPLACE WITH set(duration:)
    public func set(property: AudioMeter.AudioMeterProperty){
        switch property {
        case .speed(let ratio): setSpeed(from: ratio)
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
        minimumDuration: 0.3,
        maximumDuration: AudioMeter.slowestSpeed
    )
    
    /// Maximum duration in seconds allowed for meter speed.
    private static var slowestSpeed: Second { return 2.5 }
    
    /// Set the speed of the meter from a ratio of 0 to 1 with 1 being the longest (slowest).
    private func setSpeed(from ratio: MeterTimeRatio.Ratio){
        let filteredSpeed = AudioMeter.filter(number: ratio)
        let seconds = AudioMeter.fastTimeRatio.seconds(from: filteredSpeed)
        self.set(duration: seconds)
    }
    
    /// Set the speed of the meter in seconds. Maximum of 2.5 seconds.
    public func set(duration: Second){
        let max = AudioMeter.slowestSpeed
        let finalSeconds = (duration > max) ? max : duration
        meter.speed = finalSeconds
    }
    
    /// The duration of the meter as a ratio of 0 to 1 with 1 being the longest (slowest).
    public var speedRatio: MeterTimeRatio.Ratio {
        get {
            return AudioMeter.fastTimeRatio.ratio(from: meter.speed)
        }
        set {
            self.setSpeed(from: newValue)
        }
    }
    
    /// The duration of the meter in seconds.
    public var speed: Second {
        get {
            return meter.speed
        }
        set {
            self.set(duration: newValue)
        }
    }
}


// MARK: DYANAMIC VARS
extension AudioMeter {
    private var format: AVAudioFormat? {
        return node?.outputFormat(forBus: 0)
    }
}
