//
//  AudioSequencerProtocol.swift
//  WPAudio
//
//  Created by William Piotrowski on 10/13/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation
/*
public protocol MIDISequencerProtocol {
    
}
public protocol AudioSequencerProtocol {
    var stemPlayers: [StemPlayer] { get }
    //var sequencer: MIDISequencerProtocol? { get }
    var sequencer: AKAppleSequencer? { get }
    var isPlaying: Bool { get }
    func set(property: AudioSequencerProperty)
    func set(properties: [AudioSequencerProperty])
    
    func addObserver(_ observerClass: ObserverClass2)
    func removeObserver(_ observerClass: ObserverClass2)
    
    func reset()
}

 */
public enum AudioSequencerProperty {
    case FXSend(volume: Float)
    case outputVolume(volume: Float)
}
