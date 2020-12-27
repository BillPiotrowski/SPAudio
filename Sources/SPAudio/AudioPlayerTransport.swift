//
//  AudioPlayerTransport.swift
//  WPAudio
//
//  Created by William Piotrowski on 7/1/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import Foundation
import ReactiveSwift

// PLAY SHOULD THROW??

public protocol AudioPlayerTransport /*: Observable2*/ {
    var audioTransportState: Property<AudioTransportState> { get }
    var transportState: AudioTransportState { get }
    var isPlaying: Bool { get }
    var isPreparedToPlay: Bool { get }
    func play() throws
    func stop()
    func pause()
    func playStopToggle()
    //func prepareToPlay()
    func prepareToPlay() throws
}
extension AudioPlayerTransport {
    public func playStopToggle(){
        switch isPlaying {
        case true: stop()
        case false: try? play()
        }
    }
}
