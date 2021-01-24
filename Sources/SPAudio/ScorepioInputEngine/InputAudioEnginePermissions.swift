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
    public var speechRecognizerAuthorizationStatus: SpeechRecognition.AuthorizationStatus {
        self.speechRecognition.permission
    }
    
    public func requestSpeechRecognizerPermission(
    ) -> Promise<SpeechRecognition.AuthorizationStatus> {
        return self.speechRecognition.requestSpeechRecognizerPermission()
    }
    public var isSpeechRecognitionPermitted: Bool {
        return speechRecognizerAuthorizationStatus.isEnabled
    }
}

// MARK: RECORD PERMISSION
// MAKING THESE NOT STATIC TO ENCOURAGE INSTANTIATING BEFORE CALLING AND REDUCE SINGLETONS.
extension InputAudioEngine {
    public var recordPermission: RecordPermission {
        audioEngine.session.recordPermission
    }
    public var isRecordingPermitted: Bool {
        recordPermission.isRecordingPermitted
    }
    
    /// Requests permission from the user to use the microphone with this app.
    /// - Returns: Returns a Promise that encapsulates a Bool indicating if the user granted permission. Will return false immediately if the user has already granted or denied access.
    public func requestRecordPermission(
    ) -> Promise<Bool> {
        audioEngine.session.requestRecordPermission()
    }
}
