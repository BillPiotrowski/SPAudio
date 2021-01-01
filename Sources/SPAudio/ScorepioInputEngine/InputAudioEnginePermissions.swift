//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/1/21.
//

import Promises

// MARK: SPEECH RECOGNITION PERMISSION
// MAKING THESE NOT STATIC TO ENCOURAGE INSTANTIATING BEFORE CALLING AND REDUCE SINGLETONS.
extension InputAudioEngine {
    public var speechRecognizerAuthorizationStatus: SpeechRecognizerAuthorizationStatus {
        SpeechRecognition.speechRecognizerAuthorizationStatus
    }
    
    public func requestSpeechRecognizerPermission(
    ) -> Promise<SpeechRecognizerAuthorizationStatus> {
        return SpeechRecognition.requestSpeechRecognizerPermission()
    }
}

// MARK: RECORD PERMISSION
// MAKING THESE NOT STATIC TO ENCOURAGE INSTANTIATING BEFORE CALLING AND REDUCE SINGLETONS.
extension InputAudioEngine {
    public var recordPermission: RecordPermission {
        AudioSession.recordPermission
    }
    public var isRecordingPermitted: Bool {
        AudioSession.isRecordingPermitted
    }
    
    /// Requests permission from the user to use the microphone with this app.
    /// - Returns: Returns a Promise that encapsulates a Bool indicating if the user granted permission. Will return false immediately if the user has already granted or denied access.
    public func requestRecordPermission(
    ) -> Promise<Bool> {
        return AudioSession.requestRecordPermission()
    }
}
