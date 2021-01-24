//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/1/21.
//

import Speech
extension SpeechRecognition {
// MARK: SPEECH RECOGNIZER PERMISSION STATE
    public enum AuthorizationStatus {
        /// The user granted your app's request to perform speech recognition.
        case authorized
        /// The user denied your app's request to perform speech recognition.
        case denied
        /// The device prevents your app from performing speech recognition.
        case restricted
        /// The app's authorization status has not yet been determined. Allows the user to be promted to authorize speech recognition.
        case notDetermined
        /// If device is running below iOS 10. Should not be an issue given expected targets.
        case notSupported
        
        internal init(from sfAuthStatus: SFSpeechRecognizerAuthorizationStatus){
            guard #available(iOS 10.0, *) else {
                self = .notSupported
                return
            }
            switch sfAuthStatus {
            case .authorized: self = .authorized
            case .denied: self = .denied
            case .restricted: self = .restricted
            case .notDetermined: self = .notDetermined
            @unknown default: self = .notDetermined
            }
        }
    }
}
     
extension SpeechRecognition.AuthorizationStatus {
    /// Returns true if speech recognition is enabled for this app on this device.
    public var isEnabled: Bool {
        switch self {
        case .authorized: return true
        default: return false
        }
    }
    /// Returns true if the app can still request permission to use speech recognition. If it is false, then the device does not support, has denied access, or is not authorized to use speech recognition. User must make changes in their device settings.
    public var canRequest: Bool {
        switch self {
        case .notDetermined: return true
        default: return false
        }
    }
}
