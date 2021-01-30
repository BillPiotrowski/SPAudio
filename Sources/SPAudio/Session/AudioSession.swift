//
//  AudioSession.swift
//  Scorepio
//
//  Created by William Piotrowski on 2/1/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import AVFoundation
import Promises
import AudioKitLite
import ReactiveSwift

public class AudioSession {
    let avSession: AVAudioSession
    
    /// A property defining the state of RecordPermission for this app.
    ///
    /// - note: This property is set at launch and will only be variable if the value is .undetermined. If the value is set to .granted or .denied, the input signal will be completed and no changes will be possible.
    ///
    /// The only way to change the setting from .granted or .denied is through the iPhone settings, which will crash the app and force a restart.
    public let recordPermissionProperty: Property<RecordPermission>
    private let recordPermissionInput: Signal<RecordPermission, Never>.Observer
    
    /// Property defining the current preferred input.
    ///
    /// - warning: There is no listener on the underlying audio session so this is only updated when a change is manually made by the user in the Scorepio app. Can improve this logic.
    public let preferredInputProperty: Property<AudioPortDescription?>
    private let preferredInputInput: Signal<AudioPortDescription?, Never>.Observer
    
    /// - todo: remove singleton
    static public let avSession = AVAudioSession.sharedInstance()
    
    public init(){
        let avSession = AudioSession.avSession
        
        let initialRecordPermission = avSession.recordPermission
        let recordPermissionPipe = Signal<RecordPermission, Never>.pipe()
        
        let recordPermissionProperty = Property(
            initial: initialRecordPermission,
            then: recordPermissionPipe.output
        )
        
        // Completes signal if permission is denied or granted since only way to change is in iPhone settings.
        // Any change to iPhone settings appears to crash app, so no reason to monitor.
        switch initialRecordPermission {
        case .denied, .granted: recordPermissionPipe.input.sendCompleted()
        case .undetermined: break
        @unknown default: break
        }
        
        let preferredInputPipe = Signal<AudioPortDescription?, Never>.pipe()
        let initialPreferredInput: AudioPortDescription?
        if let input = avSession.preferredInput {
            initialPreferredInput = AudioPortDescription(
                portDescription: input
            )
        } else {
            initialPreferredInput = nil
        }
        let preferredInputProperty = Property(
            initial: initialPreferredInput,
            then: preferredInputPipe.output
        )
        
        self.avSession = avSession
        self.recordPermissionInput = recordPermissionPipe.input
        self.recordPermissionProperty = recordPermissionProperty
        self.preferredInputInput = preferredInputPipe.input
        self.preferredInputProperty = preferredInputProperty
        
        configureAudioSession()
        
    }
    
    private func configureAudioSession(){
        do {
            
            Settings.audioInputEnabled = true
            Settings.playbackWhileMuted = true
            Settings.defaultToSpeaker = true
            Settings.useBluetooth = true
            
            try Settings.setSession(category: .playAndRecord)
            if #available(iOS 10.0, *) {
                try avSession.setCategory(.playAndRecord, mode: .default, options: [.allowAirPlay, .allowBluetooth, .defaultToSpeaker, .allowBluetoothA2DP])
            } else {
                try avSession.setCategory(.playAndRecord, options: [.allowBluetooth, .defaultToSpeaker])
            }
            try avSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            
            try setDefaultInput()
            
        } catch {
            print(error)
        }
    }
    
    public func start(){
        try? avSession.setActive(true, options: [])
    }
    public func stop(){
        try? avSession.setActive(false, options: [])
    }
    
    private func setDefaultInput() throws {
        guard let firstAvailableInput = availableInputs.first
            else {
                throw AudioSessionError.settingDefaultNoAvailableInputs
        }
        try setPreferredInput(port: firstAvailableInput)
    }
    
    public func setPreferredInput(port: AudioPortDescription) throws {
        try avSession.setPreferredInput(
            port.portDescription
        )
        self.preferredInputInput.send(value: port)
    }
    
    
    
    public var availableInputs: [AudioPortDescription] {
        guard
            let inputOptions = avSession.availableInputs
            else { return  [] }
        var options = [AudioPortDescription]()
        for inputOption in inputOptions {
            options.append(
                AudioPortDescription(
                    portDescription: inputOption
                )
            )
        }
        return options
    }
    
    public var preferredInput: AudioPortDescription? {
        //print("SESSION PREFERRED IN: \(avSession.preferredInput)")
        guard let preferredInput = avSession.preferredInput
            else { return nil }
        return AudioPortDescription(portDescription: preferredInput)
    }
    
    enum AudioSessionError: ScorepioError {
        case settingDefaultNoAvailableInputs
        
        var message: String {
            switch self {
            case .settingDefaultNoAvailableInputs: return "Could not set preferred input because there are no available inputs."
            }
        }
    }
}







// MARK: RECORD PERMISSION
extension AudioSession {
    
    /// The current state of Record Permission for this app on this device.
    public var recordPermission: RecordPermission {
        recordPermissionProperty.value
    }
//    internal static var recordPermission: RecordPermission {
//        avSession.recordPermission
//    }
//    internal static var isRecordingPermitted: Bool {
//        return AudioSession.recordPermission.isRecordingPermitted
//    }
    
    /// Requests permission from the user to use the microphone with this app.
    /// - Returns: Returns a Promise that encapsulates a Bool indicating if the user granted permission. Will return false immediately if the user has already granted or denied access.
    public func requestRecordPermission(
    ) -> Promise<Bool> {
        return Promise<Bool>{ fulfill, reject in
            //avSession.requestRecordPermission{
            AudioSession.avSession.requestRecordPermission{ didGrantPermission in
                self.recordPermissionInput.send(
                    value: self.avSession.recordPermission
                )
                fulfill(didGrantPermission)
            }
        }
    }
}
