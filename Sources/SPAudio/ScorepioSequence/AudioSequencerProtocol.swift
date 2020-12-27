//
//  File.swift
//  
//
//  Created by William Piotrowski on 12/27/20.
//

import Foundation
import ReactiveSwift
import AudioKit

// USED TO PROTECT AudioSequencer from being manipulated. Can possibly use private / internal and eliminate this protocol?
public protocol AudioSequencerProtocol {
    var stemPlayers: [StemPlayer] { get }
    var sequencer: AppleSequencer? { get }
    var isPlaying: Bool { get }
    func set(property: AudioSequencer.SettableProperty)
    func set(properties: [AudioSequencer.SettableProperty])
    var sequencerStateProperty: Property<AudioSequencer.State> { get }
    
    func reset()
}

public enum AudioSequencerProperty {
   case FXSend(volume: Float)
   case outputVolume(volume: Float)
}
