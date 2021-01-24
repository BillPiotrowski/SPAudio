//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/23/21.
//

import Foundation

extension SpeechRecognition {
    /// State defining the Speech Recognition class.
    public struct State {
        /// User has allowed speech detection to be turned on via a switch in the app.
        public let isUserEnabled: Bool
        
        /// Apple has not throttled the service.
        public let isAppleAvailable: Bool
        
        /// App has permission from the device to use speech detection.
        public let permission: AuthorizationStatus
        
        /// Speech detection is currently running
        public let isRunning: Bool
        
        /// App has permission from device to use microphone / audio input.
        public let recordPermissionGranted: Bool
    }
}

extension SpeechRecognition.State {
    /// Returns true if the SpeechRecognition passes all requirements to begin.
    ///
    /// Verifies that:
    /// - recording permission is granted;
    /// - speech permission is granted;
    /// - apple has made detection available; and,
    /// - user has enabled detection.
    ///
    public var shouldStart: Bool {
        guard
            recordPermissionGranted,
            permission.isEnabled,
            isAppleAvailable,
            isUserEnabled
        else { return false }
        return true
    }
}
