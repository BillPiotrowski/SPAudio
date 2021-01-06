//
//  AudioEngineProtocol.swift
//  WPAudio
//
//  Created by William Piotrowski on 7/1/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import AVFoundation
import ReactiveSwift

@available(*, deprecated, message: "Should simply use AudioEngine class.")
public protocol AudioEngineProtocol: Observable2 {
    func stop()
    func stopIfNotRunning()
    func start() throws
    var isRunning: Bool { get }
    var engine: AVAudioEngine { get }
    var periodicUpdateSignalProducer: SignalProducer<AudioEnginePeriodicUpdate, Never> { get }
}
