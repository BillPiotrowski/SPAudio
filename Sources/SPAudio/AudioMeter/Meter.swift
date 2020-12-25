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

public struct MeterReading {
    public let intensityFast: Float
    public let intensitySlow: Float
    public let triggerWords: [String]
    
    public init(
        intensityFast: Float,
        intensitySlow: Float,
        triggerWords: [String] = []
    ){
        self.intensityFast = intensityFast
        self.intensitySlow = intensitySlow
        self.triggerWords = triggerWords
    }
}


public class AudioMeter {
    //var observations: [ObjectIdentifier : Observer] = [:]
    
    private var node: AVAudioNode?
    
    private (set) var value: Float = 0 {
        
        didSet {
            //guard let meterReading = meterReading
            //    else { return }
            if let intensityChange = intensityChange {
                intensityChange(value)
            }
            /*
            let observation = Observation.meter(reading: meterReading)
            sendToObservers(observation)
 */
            
            //self.didChange(meterReading)
        }
    }
    
    private let meter = DurationMeter()
    private let meterMinimum = MeterMinimum()
    private let meterMaximum = MeterMaximum()
    private let audioEngine: AudioEngineProtocol
    
    //private var format = AVAudioFormat()
    
    private var scale: Float = 1
    private var didChange: (MeterReading) -> Void = { (meterReading)  in }
    public var speechTrigger: (_ word: String) -> Void = { arg in } {
        didSet {
            speechRecognition.triggerCallback = speechTrigger
        }
    }
    public var intensityChange: ((Float) -> Void)?
    
    private var absoluteMinDb: Float = -60.0
    private var minDb: Float = -60.0
    //internal var running = false
    var state: State = .off
    
    public let speechRecognition = SpeechRecognition()
    
    
    /*
    private (set) var meterReading: MeterReading? {
        didSet {
            guard let meterReading = meterReading
                else { return }
            if let intensityChange = intensityChange {
                intensityChange(meterReading.intensityFast)
            }
            let observation = Observation.meter(reading: meterReading)
            sendToObservers(observation)
            
            self.didChange(meterReading)
        }
    }
    */
    
    public init(audioEngine: AudioEngineProtocol){
        self.audioEngine = audioEngine
        //self.changeSlowSpeed(ratio: self.slowSpeed)
        //meter.slowSpeedSeconds = 7
        meter.fastSpeedSeconds = 2.5
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
        
        
        let avgPower = bufferReading.decibel
        
        
        
        
        let meterLevel = volumeRatio(decibel: avgPower)
        
        
        //self.buffer = channelDataValueArray
        
        
        
        //better place to calculate only on init and change?
        let secondsMultiplier = Float(format.sampleRate) / Float(buffer.frameLength)
        
        
        meter.setTime(multiplier: secondsMultiplier)
        meter.append(scaledReading: meterLevel)
        
        meterMinimum.append(decibelReading: avgPower)
        
        if meterMinimum.average != 0{
            minDb = meterMinimum.average
        }
        
        let fastLevel = meter.fastReading * scale
        
        meterMaximum.append(scaledLevel: fastLevel)
        
        self.scale = AudioMeter.scale(maximumRatio: meterMaximum.average)
        
        //let slowLevel = AudioMeter.filter(number: meter.slowReading * scale)
        
        self.value = fastLevel
        
        /*
        self.meterReading = MeterReading(
            intensityFast: fastLevel,
            intensitySlow: slowLevel
        )
        */
        
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
        //Order matters, so both are sent on didChange. Can possibly split in to two callbacks?
        //leadingLevel = 0
        //level = 0
        //minTracker.reset()
        //maxTracker.reset()
        //trailingLevel.reset()
        //trailingLevelHalf.reset()
        
        //meterReading = nil
        value = 0
        meterMaximum.reset()
        meterMinimum.reset()
        meter.reset()
        
        //newMeter.reset()
        
        minDb = -60.0
    }
    
    // Verify performance regarding escaping!
    public func setCallback(callback: @escaping (MeterReading) -> Void){
        self.didChange = callback
    }
    
    
    public func set(property: AudioMeter.Property){
        switch property {
        case .fastSpeed(let ratio): changeFastSpeed(ratio: ratio)
        //case .slowSpeed(let ratio): changeSlowSpeed(ratio: ratio)
        }
    }
    
    public func set(properties: [AudioMeter.Property]){
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
    /*
    private func changeSlowSpeed(ratio: Float){
        //self.slowSpeed = speed
        let filteredSpeed = AudioMeter.filter(number: ratio)
        //let temp = 0.75 + (filteredSpeed * 19.5)
        let seconds = AudioMeter.slowTimeRatio.seconds(fromRatio: filteredSpeed)
        //print(temp == seconds)
        meter.slowSpeedSeconds = seconds
    }
 */
    private func changeFastSpeed(ratio: Float){
        let filteredSpeed = AudioMeter.filter(number: ratio)
        let seconds = AudioMeter.fastTimeRatio.seconds(fromRatio: filteredSpeed)
        // better way to do this in ratio??
        let finalSeconds = (seconds > 2.5) ? 2.5 : seconds
        meter.fastSpeedSeconds = finalSeconds
    }
    /*
    var slowSpeed: Float {
        return AudioMeter.slowTimeRatio.ratio(fromSeconds: meter.slowSpeedSeconds)
    }
 */
    
    /// The duration of the meter as a ratio of 0 to 1
    public var meterSpeedRatio: Float {
        return AudioMeter.fastTimeRatio.ratio(fromSeconds: meter.fastSpeedSeconds)
    }
}

// MARK: CALCULATIONS
extension AudioMeter {
    /// Calculates the scale to multiply raw level ratios by to increase dynamic range.
    static func scale(
        maximumRatio: Float,
        limit: Float? = 10
    ) -> Float{
        let limit = limit ?? 10
        let scale = 1 / maximumRatio
        return (scale > limit) ? limit : scale
    }
    
    /// convert decibel readings to a ratio of 0 to 1
    private func volumeRatio(decibel: Float) -> Float {
        return AudioMeter.volumeRatio(decibel: decibel, minimumDB: minDb)
    }
    
    /// convert decibel readings to a ratio of 0 to 1
    static func volumeRatio (
        decibel: Float,
        minimumDB: Float
    ) -> Float {
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

// MARK: DEFINITIONS
extension AudioMeter {
    
    enum AudioMeterError: ScorepioError {
        case couldNotStartAlreadyRunning
        case couldNotStartNoNode
        
        var message: String {
            switch self {
            case .couldNotStartNoNode: return "Could not start audio meter because there is not a node defined."
            case .couldNotStartAlreadyRunning: return "Could not start audio meter because it is already running."
            }
        }
    }
    
    public enum Property {
        case fastSpeed(ratio: Float)
        //case slowSpeed(ratio: Float)
    }
    
    enum State {
        case running
        case off
    }
}

