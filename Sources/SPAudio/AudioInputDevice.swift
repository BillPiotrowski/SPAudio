//
//  AudioInputDevice.swift
//  WPAudio
//
//  Created by William Piotrowski on 7/2/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//
/*
import Foundation
import SPCommon
import AVFoundation
//import AudioKit
import MediaPlayer
import WPAudio

struct AudioInputDevice {
    private let inputNode: AVAudioInputNode
    let bus: Int
    let portDescription: AudioPortDescription?
    
    init (
        inputNode: AVAudioInputNode,
        session: AudioSession,
        bus: Int? = nil
    ) throws {
        let bus = bus ?? 0
        
        // NOT SURE THIS IS A GREAT IDEA??
        //guard
        let portDescription = session.preferredInput
        //    else { throw AudioInputDeviceError.noPreferredInput }
        
        guard session.recordAllowed
            else { throw AudioInputDeviceError.micPermissionNotGranted }
        
        let format = inputNode.inputFormat(forBus: bus)
        guard format.channelCount > 0
            else { throw AudioInputDeviceError.zeroChannelCount }
        guard format.sampleRate > 0
            else { throw AudioInputDeviceError.zeroSampleRate }
        
        self.portDescription = portDescription
        self.inputNode = inputNode
        self.bus = bus
    }
    
    var numberOfInputs: Int {
        return inputNode.numberOfInputs
    }
    var numberOfOutputs: Int {
        return inputNode.numberOfOutputs
    }
    var name: String {
        return portDescription?.name ?? "Unknown"
    }
    var avNode: AVAudioNode {
        return inputNode
    }
    
    enum AudioInputDeviceError: ScorepioError {
        case zeroChannelCount
        case zeroSampleRate
        case noPreferredInput
        case micPermissionNotGranted
        
        var message: String {
            switch self {
            case .zeroChannelCount: return "Could not instantiate AudioInputDevice because channel count was not greater than 0."
            case .zeroSampleRate: return "Could not instantiate AudioInputDevice because sample rate was not greater than 0."
            case .noPreferredInput: return "Could not instantiate AudioInputDevice because session does not have a preferred input."
            case .micPermissionNotGranted: return "Could not instantiate AudioInputDevice because mic permission was not granted."
            }
        }
    }
}
*/
