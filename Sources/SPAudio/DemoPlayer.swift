//
//  DemoPlayer.swift
//  Scorepio
//
//  Created by William Piotrowski on 3/17/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation
import AVKit

class DemoPlayer {
    private let audioPlayer: AudioPlayer
    private let audioEngine: AudioEngineProtocol
    
    init(
        audioEngine: AudioEngineProtocol,
        outputConnectionPoint: AVAudioConnectionPoint
    ){
        self.audioEngine = audioEngine
        self.audioPlayer = AudioPlayer(
            audioEngine: audioEngine,
            outputConnectionPoints: [outputConnectionPoint]
        )
    }
}
