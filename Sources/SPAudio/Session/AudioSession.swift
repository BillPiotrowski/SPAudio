//
//  AudioSession.swift
//  Scorepio
//
//  Created by William Piotrowski on 2/1/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import AVFoundation
//import AudioKit
import AudioKitLite

public class AudioSession {
    let avSession = AudioSession.avSession
    static public let avSession = AVAudioSession.sharedInstance()
    
    public init(){
        configureAudioSession()
    }
    
    private func configureAudioSession(){
        do {
            
            Settings.audioInputEnabled = true
            Settings.playbackWhileMuted = true
            Settings.defaultToSpeaker = true
            Settings.useBluetooth = true
            
            try Settings.setSession(category: .playAndRecord)
            if #available(iOS 10.0, *) {
                try avSession.setCategory(.playAndRecord, mode: .default, options: [.allowAirPlay, .allowBluetooth, .defaultToSpeaker, .allowBluetoothA2DP])
            } else {
                try avSession.setCategory(.playAndRecord, options: [.allowBluetooth, .defaultToSpeaker])
            }
            try avSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            
            try setDefaultInput()
            
        } catch {
            print(error)
        }
    }
    
    public func start(){
        try? avSession.setActive(true, options: [])
    }
    public func stop(){
        try? avSession.setActive(false, options: [])
    }
    
    private func setDefaultInput() throws {
        guard let firstAvailableInput = availableInputs.first
            else {
                throw AudioSessionError.settingDefaultNoAvailableInputs
        }
        try setPreferredInput(port: firstAvailableInput)
    }
    
    public func setPreferredInput(port: AudioPortDescription) throws {
        try avSession.setPreferredInput(
            port.portDescription
        )
    }
    
    
    
    public var availableInputs: [AudioPortDescription] {
        guard
            let inputOptions = avSession.availableInputs
            else { return  [] }
        var options = [AudioPortDescription]()
        for inputOption in inputOptions {
            options.append(
                AudioPortDescription(
                    portDescription: inputOption
                )
            )
        }
        return options
    }
    
    public var preferredInput: AudioPortDescription? {
        //print("SESSION PREFERRED IN: \(avSession.preferredInput)")
        guard let preferredInput = avSession.preferredInput
            else { return nil }
        return AudioPortDescription(portDescription: preferredInput)
    }
    
    enum AudioSessionError: ScorepioError {
        case settingDefaultNoAvailableInputs
        
        var message: String {
            switch self {
            case .settingDefaultNoAvailableInputs: return "Could not set preferred input because there are no available inputs."
            }
        }
    }
}
