//
//  AudioEngineProtocol.swift
//  WPAudio
//
//  Created by William Piotrowski on 7/1/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import AVFoundation



public protocol AudioEngineProtocol: Observable2 {
    func stop()
    func stopIfNotRunning()
    func start() throws
    var isRunning: Bool { get }
    var engine: AVAudioEngine { get }
}
