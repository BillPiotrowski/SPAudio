//
//  Synth.swift
//  Swift Synth
//
//  Created by Grant Emerson on 7/21/19.
//  Copyright © 2019 Grant Emerson. All rights reserved.
//

import AVFoundation
import AudioKitLite

public class Synth {
    private let outputMixer: AVAudioMixerNode
    private let destination: AVAudioConnectionPoint
    internal let audioEngine: AudioEngine
    internal let oscillators: [OscillatorAndVCA]
    public private (set) var isConnected: Bool = false
    
    static let oscillatorCount: Int = 4
    
    
    init(
        wire to: AVAudioConnectionPoint,
        audioEngine: AudioEngine,
        signal: @escaping AudioSignal = Oscillator.sine
    ){
        let outputMixer = AVAudioMixerNode()
        
        var oscillators = [OscillatorAndVCA]()
        for i in 0..<Synth.oscillatorCount {
            let connection = AVAudioConnectionPoint(
                node: outputMixer,
                bus: i
            )
            let osc = OscillatorAndVCA(
                wire: connection,
                audioEngine: audioEngine,
                signal: signal
            )
            oscillators.append(osc)
        }
        
        
        self.oscillators = oscillators
        self.audioEngine = audioEngine
        self.outputMixer = outputMixer
        self.destination = to
        
        self.attach()
    }
}

// MARK: ATTACH
extension Synth {
    private func attach(){
        self.audioEngine.engine.attach(self.outputMixer)
    }
}


// MARK: CONNECT
extension Synth {
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
        for osc in self.oscillators {
            try osc.connect()
        }
        self.isConnected = self.checkConnection()
    }
    
    func disconnect(){
        if isPlaying { self.stop() }
        for osc in self.oscillators {
            osc.disconnect()
        }
        self.audioEngine.engine.disconnectNodeInput(self.outputMixer)
        self.isConnected = self.checkConnection()
    }
    
    func checkConnection() -> Bool{
        for osc in self.oscillators {
            guard osc.isConnected else { return false }
        }
        return outputMixer.isOutputConnected
    }
}


// MARK: POLYPHONIC
extension Synth /*: Polyphonic*/ {
    
    /// Global tuning table used by PolyphonicNode (Node classes adopting Polyphonic protocol)
    @objc public static var tuningTable = TuningTable()
    /// MIDI Instrument
//    open var midiInstrument: AVAudioUnitMIDIInstrument?

    /// Play a sound corresponding to a MIDI note with frequency
    ///
    /// - Parameters:
    ///   - noteNumber: MIDI Note Number
    ///   - velocity:   MIDI Velocity
    ///   - frequency:  Play this frequency
    ///
    open func play(
        noteNumber: MIDINoteNumber,
        velocity: MIDIVelocity,
//        frequency: AUValue,
        channel: MIDIChannel = 0
    ) {
        if !isConnected { try? self.connect() }
//        if isPlaying { self.stop() }
        let osc = self.nextOscillator
        osc.play(
            noteNumber: noteNumber,
            velocity: velocity,
//            frequency: frequency,
            channel: channel
        )
        
//        oscillator.frequency = frequency
//        try? vca.play()
//        Log("Playing note: \(noteNumber), velocity: \(velocity), frequency: \(frequency), channel: \(channel), " +
//            "override in subclass")
    }

    /// Play a sound corresponding to a MIDI note
    ///
    /// - Parameters:
    ///   - noteNumber: MIDI Note Number
    ///   - velocity:   MIDI Velocity
    ///
//    open func play(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel = 0) {
//        // Microtonal pitch lookup
//
//        // default implementation is 12 ET
//        let frequency = PolyphonicNode.tuningTable.frequency(forNoteNumber: noteNumber)
//        play(noteNumber: noteNumber, velocity: velocity, frequency: AUValue(frequency), channel: channel)
//    }

    /// Stop a sound corresponding to a MIDI note
    ///
    /// - parameter noteNumber: MIDI Note Number
    ///
    open func stop(noteNumber: MIDINoteNumber) {
        for osc in self.oscillators(playing: noteNumber){
            osc.stop()
        }
//        vca.stop()
//        Log("Stopping note \(noteNumber), override in subclass")
    }
    
}


// MARK: PRIVATE HELPER
extension Synth {
    // CAN IMPROVE THIS LOGIC
    internal var nextOscillator: OscillatorAndVCA {
        if let firstNotPlaying = self.firstNotPlaying {
            return firstNotPlaying
        }
        if let highestOscillatorPlaying = self.highestOscillatorPlaying {
            return highestOscillatorPlaying
        }
        // Should never get here logically.
        return oscillators[0]
//        if let firstNotPlaying = oscillators.first(where: { !$0.isPlaying }) {
//            return firstNotPlaying
//        }
//        if let highestPitch = oscillators.max(by: { $0.noteNumber < $1.noteNumber }) {
//            return highestPitch
//        }
//
//        let temp = oscillators.sorted(by: { $0.noteNumber > $1.noteNumber })
    }
    
    private func oscillators(playing: MIDINoteNumber) -> [OscillatorAndVCA] {
        var subset = [OscillatorAndVCA]()
        for osc in oscillators {
            if osc.noteNumber == playing {
                subset.append(osc)
            }
        }
        return subset
    }
    internal var playingOscillators: [OscillatorAndVCA] {
        return oscillators.compactMap{
            guard $0.isPlaying
            else { return nil }
            return $0
        }
    }
    internal var playingOscillatorsCount: Int {
        return playingOscillators.count
    }
    internal var notPlayingOscillators: [OscillatorAndVCA] {
        return oscillators.compactMap{
            guard !$0.isPlaying
            else { return nil }
            return $0
        }
    }
    internal var notPlayingOscillatorsCount: Int {
        return notPlayingOscillators.count
    }
    internal var oscillatorsPlayingLowToHigh: [OscillatorAndVCA] {
        return playingOscillators.sorted(
            by: { $0.noteNumber < $1.noteNumber }
        )
    }
    var highestOscillatorPlaying: OscillatorAndVCA? {
        return oscillatorsPlayingLowToHigh.last
    }
    var lowestOscillatorPlaying: OscillatorAndVCA? {
        return oscillatorsPlayingLowToHigh.first
    }
    var firstNotPlaying: OscillatorAndVCA? {
        return notPlayingOscillators.first
    }
}

extension Synth {
    /// Stops all oscillators.
    func stop(){
        for osc in oscillators {
            osc.stop()
        }
    }
}

// MARK: COMPUTED VARS
extension Synth {
    private var audioFormat: AVAudioFormat {
        return audioEngine.engine.outputNode.inputFormat(forBus: 0)
    }
    var isPlaying: Bool {
        for osc in self.oscillators {
            guard !osc.isPlaying else { return true }
        }
        return false
    }
}
