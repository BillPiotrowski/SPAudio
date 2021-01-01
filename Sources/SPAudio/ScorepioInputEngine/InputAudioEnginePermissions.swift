//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/1/21.
//

import Foundation

// MARK: SPEECH RECOGNITION PERMISSION
extension InputAudioEngine {
    public static let speechRecognizerAuthorizationStatus = SpeechRecognition.speechRecognizerAuthorizationStatus
    
    public static func requestSpeechRecognizerPermission(
    ) throws -> Promise<SpeechRecognizerAuthorizationStatus> {
        return SpeechRecognition.requestSpeechRecognizerPermission()
    }
}

// MARK: RECORD PERMISSION
extension InputAudioEngine {
    public static var recordPermission = AudioSession.recordPermission
    public static var isRecordingPermitted = AudioSession.isRecordingPermitted
    
    /// Requests permission from the user to use the microphone with this app.
    /// - Returns: Returns a Promise that encapsulates a Bool indicating if the user granted permission. Will return false immediately if the user has already granted or denied access.
    public static func requestRecordPermission(
    ) -> Promise<Bool> {
        return AudioSession.requestRecordPermission()
    }
}
