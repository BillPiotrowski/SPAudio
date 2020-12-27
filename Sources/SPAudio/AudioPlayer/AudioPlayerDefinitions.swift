//
//  File.swift
//  
//
//  Created by William Piotrowski on 12/26/20.
//

import Foundation
import SPCommon

// MARK: DEFINITIONS
extension AudioPlayer {
    public enum State {
        case standby
        case cued(transport: AudioPlayerTransport)
    }
    
    enum Error: ScorepioError {
        case couldNotLoadAudio(url: URL)
        case connectNoFormat
        case connectNoOutput
        case scheduleNoAudioFile
        
        var message: String {
            switch self {
            case .couldNotLoadAudio(let url): return "Could not load audio file: \(url.relativeString)."
            case .connectNoFormat: return "Can not connect audio player because there is no audio format."
            case .connectNoOutput: return "Can not connect audio player because there are no output connection points."
            case .scheduleNoAudioFile: return "Could not schedule player because audio file is not defined."
            }
        }
    }
}
