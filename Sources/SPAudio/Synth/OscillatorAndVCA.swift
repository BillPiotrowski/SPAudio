//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/5/21.
//

import AVFoundation
import AudioKitLite

class OscillatorAndVCA {
    private let oscillator: OscillatorNode
    private let vca: VCA
    public private (set) var isConnected: Bool = false
    
    // HAVE THIS SENT TO OSC AT INIT? IT IS CURRENTLY ARBITRARY UNTIL SET.
    var noteNumber: MIDINoteNumber = 64
    
    init(
        wire to: AVAudioConnectionPoint,
        audioEngine: AudioEngine,
        signal: @escaping AudioSignal = Oscillator.sine
    ){
        let vca = VCA(wire: to, audioEngine: audioEngine)
        let connection = AVAudioConnectionPoint(node: vca.node, bus: 0)
        let oscillator = OscillatorNode(
            wire: connection,
            engine: audioEngine,
            signal: signal
        )
        
        self.oscillator = oscillator
        self.vca = vca
    }
}

// MARK: CONNECT
extension OscillatorAndVCA {
    func connect() throws {
        guard !isConnected else {
            throw NSError(domain: "Trying to connect, but already connected", code: 1, userInfo: nil)
        }
        try vca.connect()
        try oscillator.connect()
        self.isConnected = self.checkConnection()
    }
    
    func disconnect(){
        if isPlaying { self.stop() }
        self.oscillator.disconnect()
        self.vca.disconnect()
        self.isConnected = self.checkConnection()
    }
    
    func checkConnection() -> Bool{
        return
            self.oscillator.isConnected &&
            self.vca.isConnected
    }
}


extension OscillatorAndVCA/*: Polyphonic*/ {
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
        frequency: AUValue,
        channel: MIDIChannel = 0
    ) {
        if !isConnected { try? self.connect() }
        if isPlaying { self.stop() }
        oscillator.frequency = frequency
        try? vca.play()
        self.noteNumber = noteNumber
//        Log("Playing note: \(noteNumber), velocity: \(velocity), frequency: \(frequency), channel: \(channel), " +
//            "override in subclass")
    }

    /// Play a sound corresponding to a MIDI note
    ///
    /// - Parameters:
    ///   - noteNumber: MIDI Note Number
    ///   - velocity:   MIDI Velocity
    ///
    open func play(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel = 0) {
        // Microtonal pitch lookup

        // default implementation is 12 ET
        let frequency = PolyphonicNode.tuningTable.frequency(forNoteNumber: noteNumber)
        play(noteNumber: noteNumber, velocity: velocity, frequency: AUValue(frequency), channel: channel)
    }

    /// Stop a sound corresponding to a MIDI note
    ///
    /// - parameter noteNumber: MIDI Note Number
    ///
    open func stop(/*noteNumber: MIDINoteNumber*/) {
        vca.stop()
//        Log("Stopping note \(noteNumber), override in subclass")
    }
    
}


extension OscillatorAndVCA {
    var isPlaying: Bool {
        return self.vca.isPlaying
    }
    
    public func setWaveformTo(_ signal: @escaping AudioSignal) {
        self.oscillator.setWaveformTo(signal)
    }
}
