//
//  File.swift
//  
//
//  Created by William Piotrowski on 12/27/20.
//

import ReactiveSwift
import SPCommon

// MARK: TRANSPORT
extension StemPlayer: AudioPlayerTransport{
    
    public var audioTransportState: Property<AudioTransportState> {
        return audioPlayer.audioTransportState
    }
    public var transportState: AudioTransportState {
        return audioPlayer.transportState
    }
    
    public var isPlaying: Bool {
        return audioPlayer.isPlaying
    }
    
    public var isPreparedToPlay: Bool {
        guard isConnected else { return false }
        return audioPlayer.isPreparedToPlay
    }
    
    public func play() throws {
        if !isPreparedToPlay {
            try prepareToPlay()
        }
        try? audioPlayer.play()
    }
    
    public func stop() {
        audioPlayer.stop()
        //disconnect()
    }
    public func pause() {
        audioPlayer.pause()
    }
    
    public func playStopToggle() {
        audioPlayer.playStopToggle()
    }
    
    public func prepareToPlay() throws {
        if !isConnected { try connect() }
        if !audioPlayer.isPreparedToPlay { try audioPlayer.prepareToPlay() }
    }
}
