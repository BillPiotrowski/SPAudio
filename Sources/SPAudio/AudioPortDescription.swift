//
//  AudioPortDescription.swift
//  Scorepio
//
//  Created by William Piotrowski on 2/1/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import AVFoundation

public struct AudioPortDescription {
    let portDescription: AVAudioSessionPortDescription
    //let name: String
    
    init(portDescription: AVAudioSessionPortDescription){
        self.portDescription = portDescription
        //self.name = portDescription.portName
        //portDescription.portType
    }
    
    public var name: String {
        switch portDescription.portType {
        case .airPlay: return "Airplay"
        case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
            return "Bluetooth"
        case .builtInMic: return "Built-in Mic"
        case .builtInReceiver: return "Built-in Receiver"
        case .builtInSpeaker: return "Built-in Speaker"
        case .carAudio: return "Car Audio"
        case .HDMI: return "HDMI"
        case .headphones: return "Headphones"
        case .headsetMic: return "Headset Mic"
        case .lineIn: return "Line In"
        case .lineOut: return "Line Out"
        case .usbAudio: return "USB Audio"
        default: return "Unknown"
        }
    }
}
