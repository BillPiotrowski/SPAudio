//
//  SpeechRecognition.swift
//  Scorepio
//
//  Created by William Piotrowski on 1/22/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import Speech
import Promises
import ReactiveSwift

/// Class responsible for handling all speech recognition tasks and maintaining the status of speech recognition permissions.
public class SpeechRecognition: NSObject {
    
    
    private let speechRecognizer = SFSpeechRecognizer()
    private unowned let audioSession: AudioSession
    
    
    // NEEDS TO BE A NEW REQUEST EACH TIME: "Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'SFSpeechAudioBufferRecognitionRequest cannot be re-used'"
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    
    var triggerCallback: (_ word: String) -> Void = { arg in }
    
    var triggersWords: [String] = ["thunder"]
    
    /// The property of whether or not the user has enabled speech detection during this session. Can be enabled or disabled at any time by changing the isUserEnabled value.
    let isUserEnabledProperty: Property<Bool>
    private let userEnabledInput: Signal<Bool, Never>.Observer
    
    /// Whether or not Apple has throttled the service. May also indicate that there are network issues. More information on the isAppleAvailable property of this class.
    let isAppleAvailableProperty: Property<Bool>
    private let appleAvailableInput: Signal<Bool, Never>.Observer
    
    /// The state of speech recognition permission for this app on this device.
    ///
    /// - note: Once this is in a state of granted or denied and not undetermined, then the signal is completed and will not change.
    let permissionProperty: Property<AuthorizationStatus>
    private let permissionInput: Signal<AuthorizationStatus, Never>.Observer
    
    /// Indicates whether the speech recognition class is currently running.
    let isRunningProperty: Property<Bool>
    private let isRunningInput: Signal<Bool, Never>.Observer
    
    /// A steam of the most recent word or utterance detected by speech recognition.
    ///
    /// - note: Skips repeats.
    public let wordSignal: Signal<String, Never>
    private let wordInput: Signal<String, Never>.Observer
    
    static let defaultIsEnabled = false
    
    
    init(audioSession: AudioSession){
        
    
        
        let userEnabledPipe = Signal<Bool, Never>.pipe()
        let appleAvailablePipe = Signal<Bool, Never>.pipe()
        let permissionPipe = Signal<AuthorizationStatus, Never>.pipe()
        let isRunningPipe = Signal<Bool, Never>.pipe()
        
        let initialIsUserEnabled = SpeechRecognition.defaultIsEnabled
        let initialIsAppleAvailable = SpeechRecognition.isAvailable
        let initialPermission =  SpeechRecognition.authorizationStatus
        let initialIsRunning = false
        
        
        let isUserEnabledProperty = Property(
            initial: initialIsUserEnabled,
            then: userEnabledPipe.output
        )
        let appleAvailableProperty = Property(
            initial: initialIsAppleAvailable,
            then: appleAvailablePipe.output
        )
        let permissionProperty = Property(
            initial: initialPermission,
            then: permissionPipe.output
        )
        let isRunningProperty = Property(
            initial: initialIsRunning,
            then: isRunningPipe.output
        )
        
        let wordPipe = Signal<String, Never>.pipe()
        
        
        self.audioSession = audioSession
        self.isUserEnabledProperty = isUserEnabledProperty
        self.isAppleAvailableProperty = appleAvailableProperty
        self.permissionProperty = permissionProperty
        self.isRunningProperty = isRunningProperty
        
        self.userEnabledInput = userEnabledPipe.input
        self.appleAvailableInput = appleAvailablePipe.input
        self.permissionInput = permissionPipe.input
        self.isRunningInput = isRunningPipe.input
        self.wordInput = wordPipe.input
        self.wordSignal = wordPipe.output.skipRepeats()
        
        super.init()
        
        // Setting speech permission manually which will close signal if not changable
        self.permission = initialPermission
        
        self.speechRecognizer?.delegate = self
        
        
        
    }
}
    
    
    
// MARK: - START / STOP
extension SpeechRecognition {
    /// Begins speech recognition.
    ///
    /// - note: Will first check with state.shouldStart to make sure permissions and other settings allow speech recognition to begin.
    public func start(){
        guard state.shouldStart
        else { return }
        self.isRunning = true
        setupRequest()
    }
    
    /// Stops and cancels all requests.
    public func stop(){
        self.isRunning = false
        request?.endAudio()
        recognitionTask?.cancel()
        request = nil
        recognitionTask = nil
    }
}
 

// MARK: - REQUEST / TASK HANDLER
extension SpeechRecognition {
    
    
    // make throwing. ao callers know if setup work and can changr state on gaf FAIL
    private func setupRequest(){
        let request = SFSpeechAudioBufferRecognitionRequest()
        guard let speechRecognizer = speechRecognizer
        else {
            // Push error to state?
            print("Could not set up speech recognition. speechRecognizer does not exist.")
            return
        }
        self.request = request
        self.recognitionTask = speechRecognizer.recognitionTask(
            with: request
        ) { [unowned self] (result, error) in
            self.taskHandler(result: result, error: error)
        }
    }
    
    func taskHandler(result: SFSpeechRecognitionResult?, error: Error?){
        if let error = error {
            print("TRANSCRIPTION ERROR: \(error.localizedDescription).")
        }
        if let transcription = result?.bestTranscription {
//            result?.transcriptions
            // BUILD IN CONFIDENCE CHECK
            guard let string = transcription.segments.last?.substring else {
                return
            }
//            transcription.segments.last!.timestamp
//            print(string)
            wordInput.send(value: string)
//            dump(transcription.segments.last?.alternativeSubstrings)
            let uppercasedTriggerWords = triggersWords.map { $0.uppercased() }
            if uppercasedTriggerWords.contains(string.uppercased()){
                //print("TRIGGER FROM SPEECH RECOGNITION: \(string)!")
                triggerCallback(string)
            }
        }
    }
    
    
    func append(buffer: AVAudioPCMBuffer){
        guard self.isRunning
        else { return }
        
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


// MARK: - PERMISSIONS
extension SpeechRecognition {
    private static var authorizationStatus: AuthorizationStatus {
        AuthorizationStatus(
            from: SFSpeechRecognizer.authorizationStatus()
        )
    }
    
}





// MARK: - AVAILABLE

/// - note: Default behaviot to crash app when settings are changed that affect permissions:
/// https://stackoverflow.com/questions/43974752/app-crashes-in-background-while-changing-permission-swift
extension SpeechRecognition: SFSpeechRecognizerDelegate {
    
    /// Is available from Apple. This feature can be throttled by apple and can depend on network access. Unsure if this changes when network access changes. Will need to test.
    ///
    /// From Apple:
    ///
    /// Be prepared to handle failures caused by speech recognition limits. Because speech recognition is a network-based service, limits are enforced so that the service can remain freely available to all apps. Individual devices may be limited in the number of recognitions that can be performed per day, and each app may be throttled globally based on the number of requests it makes per day.
    ///
    /// https://developer.apple.com/documentation/speech/sfspeechrecognizer
    ///
    /// https://stackoverflow.com/questions/39249003/speech-recognition-limits-for-ios-10
    ///
    /// https://developer.apple.com/library/archive/qa/qa1951/_index.html#//apple_ref/doc/uid/DTS40017662
    ///
    /// https://stackoverflow.com/questions/59117311/does-sfspeechrecognizer-have-a-limit-if-supportsondevicerecognition-is-true-and
    ///
    /// https://developer.apple.com/videos/play/wwdc2019/256/
    /// - Note: Choosing to make SPSpeechRecognizer not the source, but the Scorepio SpeechRecognition State Property. Depending on Apple correctly sending updates, via SFSpeechRecognizerDelegate
    public var isAppleAvailable: Bool {
        isAppleAvailableProperty.value
    }
    
    /// This is used to set initial value when instantiated SpeechRecognition.
    private static var isAvailable: Bool {
        SFSpeechRecognizer()?.isAvailable ?? false
    }
    
    public func speechRecognizer(
        _ speechRecognizer: SFSpeechRecognizer,
        availabilityDidChange available: Bool
    ){
        self.appleAvailableInput.send(value: available)
    }
}




// MARK: - STATE HELPERS
extension SpeechRecognition {
    public private (set) var isRunning: Bool {
        get { return isRunningProperty.value }
        set {
            self.isRunningInput.send(value: newValue)
        }
    }
    public var isUserEnabled: Bool {
        get { isUserEnabledProperty.value }
        set {
            if !newValue {
                self.stop()
            }
            self.userEnabledInput.send(value: newValue)
        }
    }
    public private (set) var permission: AuthorizationStatus {
        get { permissionProperty.value }
        set {
            permissionInput.send(value: newValue)
            
            // Closes signal if can not request. Would require a change in iPhone settings which will crash app to change. No reason to keep signal open.
            if !newValue.canRequest {
                permissionInput.sendCompleted()
            }
        }
    }
    
    public var state: State {
        State(
            isUserEnabled: isUserEnabled,
            isAppleAvailable: isAppleAvailable,
            permission: permission,
            isRunning: isRunning,
            recordPermissionGranted: audioSession.recordPermission.isRecordingPermitted
        )
    }
}

// MARK: - SIGNAL PRODUCER
extension SpeechRecognition {
    public var stateSignalProducer: SignalProducer<State, Never> {
        SignalProducer.combineLatest(
            isUserEnabledProperty.producer,
            isAppleAvailableProperty.producer,
            permissionProperty.producer,
            isRunningProperty.producer,
            audioSession.recordPermissionProperty.producer
        ).map {
            return State(
                isUserEnabled: $0.0,
                isAppleAvailable: $0.1,
                permission: $0.2,
                isRunning: $0.3,
                recordPermissionGranted: $0.4.isRecordingPermitted
            )
        }
    }
}

extension SpeechRecognition {
    var isOnDeviceRecognitionSupported: Bool {
        guard #available(iOS 13, *) else {
            return false
        }
        return speechRecognizer?.supportsOnDeviceRecognition ?? false
    }
}


// MARK: - REQUEST SPEECH DETECTION PERMISSION
extension SpeechRecognition {
    // WOULD PREFER THESE BE INTERNAL AND NOT A SINGLETON
    public func requestSpeechRecognizerPermission(
    ) -> Promise<AuthorizationStatus> {
        return Promise<AuthorizationStatus>(on: .main) { fulfill, reject in
            guard #available(iOS 10.0, *) else {
                reject(SpeechRecognitionError.iOSNotSupported)
                return
            }
            guard self.permission.canRequest
            else {
                reject(SpeechRecognitionError.cantRequestSpeechPermission)
                return
            }
            SFSpeechRecognizer.requestAuthorization() { authStatus in
                let status = AuthorizationStatus(from: authStatus)
                self.permission = status
                fulfill(status)
            }
        }
    }
}


// MARK: - DEFINITIONS
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
