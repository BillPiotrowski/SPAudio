//
//  SpeechRecognition.swift
//  Scorepio
//
//  Created by William Piotrowski on 1/22/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import Speech

public class SpeechRecognition {
    
    let speechRecognizer = SFSpeechRecognizer()
    // NEEDS TO BE A NEW REQUEST EACH TIME: "Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'SFSpeechAudioBufferRecognitionRequest cannot be re-used'"
    var request: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    var state: SpeechRecognition.State = .off
    
    var triggerCallback: (_ word: String) -> Void = { arg in }
    
    var triggersWords: [String] = ["thunder"]
    
    enum State {
        case off
        case on
    }
    
    /*
    func authorize(){
        if #available(iOS 10.0, *) {
            SFSpeechRecognizer.requestAuthorization {
                [unowned self] (authStatus) in
                switch authStatus {
                case .authorized:
                    print("AUTHORIZED")
                    //if let recording = self.recording {
                    //TODO: Kick off the transcription
                //}
                case .denied:
                    print("Speech recognition authorization denied")
                case .restricted:
                    print("Not available on this device")
                case .notDetermined:
                    print("Not determined")
                @unknown default: break
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    */
    
    func start(){
        try? requestSpeechRecognizerPermission()
        //authorize()
        setupRequest()
        state = .on
    }
    
    func setupRequest(){
        request = SFSpeechAudioBufferRecognitionRequest()
        guard
            let speechRecognizer = speechRecognizer,
            let request = request
        else {
            print("Could not set up speech recognition. speechRecognizer or request object does not exist.")
            return
        }
        recognitionTask = speechRecognizer.recognitionTask(with: request) {
            [unowned self]
            (result, error) in
            
            self.taskHandler(result: result, error: error)
        }
    }
    
    func taskHandler(result: SFSpeechRecognitionResult?, error: Error?){
        if let error = error {
            print("TRANSCRIPTION ERROR: \(error.localizedDescription).")
        }
        if let transcription = result?.bestTranscription {
            //print(transcription.formattedString)
            // SFTranscriptionSegment
            // BUILD IN CONFIDENCE CHECK
            guard let string = transcription.segments.last?.substring else {
                return
            }
            print(string)
            //dump(transcription.segments.last?.alternativeSubstrings)
            let uppercasedTriggerWords = triggersWords.map { $0.uppercased() }
            if uppercasedTriggerWords.contains(string.uppercased()){
                //print("TRIGGER FROM SPEECH RECOGNITION: \(string)!")
                triggerCallback(string)
            }
        }
    }
    
    
    func stop(){
        recognitionTask?.cancel()
        request?.endAudio()
        state = .off
    }
    
    func append(buffer: AVAudioPCMBuffer){
        guard state == .on else {
            // STOP if running??
            return
        }
        
        if recognitionTask?.state != SFSpeechRecognitionTaskState.running {
            print("Speech recognition state is expected to be running, but instead is: \(String(describing: recognitionTask?.state))")
            setupRequest()
        }
        guard let request = request else {
            print("Could not add buffer to speech recognition request because request does not exist.")
            return
        }
        
        request.append(buffer)
    }
    
}

// MARK: PERMISSION
extension SpeechRecognition {
    public enum SpeechRecognizerPermission {
        case authorized, denied, restricted, notDetermined
        
        var enabled: Bool {
            switch self {
            case .authorized: return true
            default: return false
            }
        }
    }
    
    public var speechRecognizerPermission: SpeechRecognizerPermission {
        return SpeechRecognition.speechRecognizerPermission(
            fromSFAuthStatus: SFSpeechRecognizer.authorizationStatus()
        )
    }
    
    static func speechRecognizerPermission(
        fromSFAuthStatus: SFSpeechRecognizerAuthorizationStatus
    ) -> SpeechRecognizerPermission {
        switch fromSFAuthStatus {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: fatalError()
        }
    }
    
    public func requestSpeechRecognizerPermission(
        callback: ((Bool) -> Void)? = nil
    ) throws {
        if #available(iOS 10.0, *) {
            SFSpeechRecognizer.requestAuthorization() {
                authStatus in
                let speechRecognizerPermission = SpeechRecognition.speechRecognizerPermission(
                    fromSFAuthStatus: authStatus
                )
                guard let callback = callback else { return }
                callback(speechRecognizerPermission.enabled)
            }
        } else {
            throw SpeechRecognitionError.iOSNotSupported
        }
    }
}


// MARK: DEFINITIONS
extension SpeechRecognition {
    enum SpeechRecognitionError: ScorepioError {
        case iOSNotSupported
        
        var message: String {
            switch self {
            case .iOSNotSupported: return "Speech Recognition is not supported on this version of iOS. Please update to iOS 10.0 or greater."
            }
        }
    }
}



