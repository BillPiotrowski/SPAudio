//
//  AudioTransportState.swift
//  WPAudio
//
//  Created by William Piotrowski on 7/1/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//
/*

import SPCommon
public enum AudioTransportState: String, Typeguard {
    case playing = "playing"
    case paused = "paused"
    case stopped = "stopped"
    
    public init(any: Any?) throws {
        let audioTransportString = try Self.asString(value: any, key: "Audio Transport State String")
        guard
            let state = AudioTransportState(
                rawValue: audioTransportString
            )
            else {
                throw TransportError.stringDoesNotMatch(
                    string: audioTransportString
                )
        }
        self = state
    }
    
    enum TransportError: ScorepioError {
        case stringDoesNotMatch(string: String)
        
        var message: String {
            switch self{
            case .stringDoesNotMatch(let string):
                return "Could not initialize AudioTransportState because string: \(string) does not match playing, paused or stopped."
            }
        }
    }
}
*/
