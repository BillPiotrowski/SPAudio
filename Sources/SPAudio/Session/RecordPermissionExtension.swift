//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/1/21.
//

import AVFoundation

public typealias RecordPermission = AVAudioSession.RecordPermission

extension RecordPermission {
    /// Returns true if recording is permitted on this device for this app.
    public var isRecordingPermitted: Bool {
        switch self {
        case .denied: return false
        case .granted: return true
        case .undetermined: return false
        @unknown default: return false
        }
    }
    
    /// Returns true if the user has not yet granted or denied permission to use recording.
    public var canRequest: Bool {
        switch self {
        case .denied: return false
        case .granted: return false
        case .undetermined: return true
        @unknown default: return false
        }
    }
}
