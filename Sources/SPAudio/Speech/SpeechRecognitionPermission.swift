//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/1/21.
//

import SPCommon
import Speech
import Promises

extension SpeechRecognition {
    public static var speechRecognizerAuthorizationStatus: SpeechRecognizerAuthorizationStatus {
        return SpeechRecognizerAuthorizationStatus(
            from: SFSpeechRecognizer.authorizationStatus()
        )
    }
    
    public static func requestSpeechRecognizerPermission(
    ) throws -> Promise<SpeechRecognizerAuthorizationStatus> {
        return Promise<SpeechRecognizerAuthorizationStatus>(on: .main) { fulfill, reject in
            guard #available(iOS 10.0, *) else {
                reject(SpeechRecognitionError.iOSNotSupported)
                return
            }
            guard Self.speechRecognizerAuthorizationStatus.canRequest else {
                reject(SpeechRecognitionError.cantRequestSpeechPermission)
                return
            }
            SFSpeechRecognizer.requestAuthorization() { authStatus in
                fulfill(
                    SpeechRecognizerAuthorizationStatus(from: authStatus)
                )
            }
        }
        
    }
}

// MARK: DEFINITIONS
private enum SpeechRecognitionError: ScorepioError {
    case iOSNotSupported
    case cantRequestSpeechPermission
    
    var message: String {
        switch self {
        case .iOSNotSupported: return "Speech Recognition is not supported on this version of iOS. Please update to iOS 10.0 or greater."
        case .cantRequestSpeechPermission: return "Can not request permission to use speech recognition. Speech recognition is not supported, not authorized or has already been denied for this app."
        }
    }
}
